---
title: Mocking aws-sdk With Jest
date: 2021-11-16
tags:
- javascript
- jest
- AWS
- testing
thumbnail: coffee_pour_thumb.jpg
teaser: How can the aws-sdk be mocked using jest?
---

_A technique for mocking [aws-sdk](https://aws.amazon.com/sdk-for-javascript/) methods with [jest](https://jestjs.io/) without the use of [aws-sdk-mock](https://www.npmjs.com/package/aws-sdk-mock)._

## Problem

Your Node.js application uses the [aws-sdk](https://aws.amazon.com/sdk-for-javascript/) NPM module via functions like `getEksClusterCount`, for example:

```javascript
import AWS from 'aws-sdk';

const export getEksClusterCount = async () => {
  const eks = new AWS.EKS();

  try {
    const clusters = await eks.listClusters().promise();

    return clusters.length;
  catch (e) {
    throw e;
  }
};
```

How can `getEksClusterCount`'s use of `AWS.EKS` be mocked out for unit testing? [aws-sdk-mock](https://www.npmjs.com/package/aws-sdk-mock) offers one solution, but how might `aws-sdk` be mocked using [jest](https://jestjs.io/), circumventing the need to use [aws-sdk-mock](https://www.npmjs.com/package/aws-sdk-mock)?

## A solution

`jest.mock` enables mocking the entire `aws-sdk` module. Because `getEksClusterCount` only makes use of `EKS`, we can mock `EKS`, but otherwise `require` other, un-mocked `aws-sdk` classes:

```javascript
const mockEks = {
  listClusters: jest.fn().mockReturnThis(),
  promise: jest.fn()
}:

jest.mock('aws-sdk', () => {
  return {
    ...jest.requireActual('aws-sdk'),
    EKS: jest.fn(() => mockEks),
  };
});
```

Then, in tests, `EKS#listClusters.promise` can be mocked to behave as needed.

For example, its promise can be mocked to successfully resolve:

```javascript
mockEks.promise.mockResolvedValueOnce({
  clusters: ['cluster-1'],
}),
```

...or mocked to reject:

```javascript
mockEks.promise.mockRejectedValueOnce('some error');
```

## A basic example

A more complete, in-context example might look like this:

```javascript
const mockEks = {
  listClusters: jest.fn().mockReturnThis(),
  promise: jest.fn()
}:

jest.mock('aws-sdk', () => {
  return {
    ...jest.requireActual('aws-sdk'),
    EKS: jest.fn(() => mockEks),
  };
});

describe('collectEksDetails', () => {
  describe('when it successfully lists EKS clusters', () => {
    it('reports the cluster count', async () => {
      const clusters = [
        'cluster-1',
        'cluster-2',
      ];

      mockEks.promise.mockResolvedValueOnce({
        clusters,
      });

      expect(async () => {
        const count = await getEksClusterCount();
        expect(count).toEqual(clusters.length);
      }).not.toThrow();
    });
  });

  describe('when it encounters an error listing EKS clusters', () => {
    it('throws an error', async () => {
      const errorMessage = 'some error';

      mockEks.promise.mockRejectedValueOnce(errorMessage);

      try {
        await getEksClusterCount();
      } catch (e) {
        expect(e).toEqual(errorMessage);
      }
    });
  });
});
```

## A more complex example

But what about testing a function that utilizes _multiple_ `EKS` methods?

For example, `listEksClusterVersions` utilizes both `EKS#listClusters` and `EKS#describeCluster`:

```javascript
import AWS from 'aws-sdk';

const export listEksClusterVersions = async () => {
  const eks = new AWS.EKS();

  try {
    let versions = [];
    const clusters = await eks.listClusters().promise();

    for (let cluster of clusters) {
      const details = await eks.describeCluster({ name: cluster }).promise();
      versions.push(details.cluster.version);
    }

    return versions;
  } catch (e) {
    throw e;
  }
};
```

In testing `listEksClusterVersions`, the initially-described `mockEks` wouldn't offer sufficiently granular control of each `EKS` method's behavior, as it assumes all `EKS` methods share the same `EKS#promise`.

To independently mock `EKS#listClusters` and `EKS#describeCluster`, a different approach is necessary; `mockEks` methods can no longer share an `EKS#promise`:

```javascript
const mockEks = {
  listClusters: jest.fn(),
  describeClusters: jest.fn(),
}:

jest.mock('aws-sdk', () => {
  return {
    ...jest.requireActual('aws-sdk'),
    EKS: jest.fn(() => mockEks),
  };
});
```

Then, in tests, `EKS#listClusters.promise` and `EKS#describeCluster.promise` can be mocked independently.

For example, each can be mocked to resolve its promise:

```javascript
mockEks.listClusters.mockReturnValue({
  promise: () => Promise.resolve(['cluster-1']),
});

mockEks.describeCluster.mockReturnValue({
  promise: () => Promise.resolve({
    cluster: {
      version: '0.0.1',
    },
  }),
});
```

...or mocked to reject its promise:

```javascript
mockEks.listClusters.mockReturnValue({
  promise: () => Promise.reject('some error'),
});

mockEks.describeCluster.mockReturnValue({
  promise: () => Promise.reject('a different error'),
});
```

In effect, this technique offers sufficiently granular control to test `listClusterVersions`'s behavior across all scenarios:

1. `listClusters` resolves; `describeCluster` resolves
1. `listClusters` rejects; `describeCluster` rejects
1. `listClusters` resolves; `describeCluster` rejects
1. `listClusters` rejects; `describeCluster` resolves
