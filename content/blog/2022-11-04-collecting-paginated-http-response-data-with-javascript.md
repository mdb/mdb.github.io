---
title: Collecting Paginated HTTP API Response Data Using JavaScript's async/await
date: 2022-11-04
tags:
- javascript
- async
- await
- notes
thumbnail: zig_zag2_thumb.jpg
teaser: Collect all pages of data from a paginated HTTP API in JavaScript using async/await.
---

_Collecting all pages of data from a paginated HTTP API can be a bit tricky in JavaScript, especially for developers who are less familiar with asynchronous JavaScript's nuances. The following offers a reference example using JavaScript's `async`/`await`._

## Problem

You need to fetch all pages of data from a paginated HTTP API in JavaScript; you'd like to do so using [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch), and you'd like to leverage [async/await](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function). While this is a relatively common scenario, how best to tackle it in JavaScript using `async`/`await` is a bit tricky.

To establish a bit more context, let's imagine...

* The API is hosted at `https://foo.bar`.
* The API's `/results` endpoint returns JSON array response body such as `["foo", "bar"]`.
* The API's `/results` endpoint accepts an optional `page` query parameter, the inclusion of which returns the specified page of results. For example, `https://foo.bar/results?page=2` returns the second page of results.
* The omission of a `page` query parameter from `https://foo.bar/results` returns the first page of results.
* Each HTTP response from the `/results` endpoint returns an `x-next-page` HTTP response header specifying the next page number. For example, `x-next-page: 2` indicates that `2` is the next page of results.
* The final page of results returned by the `/results` endpoint has no `x-next-page` response header, thereby indicating it's the final page of results.

## Solution

A recursive `fetchResults` function collects and concatenates all pages' results by recursively calling itself, concatenating each page's results to a `results` array:

```javascript
const fetchResults = page => {
  const baseUrl = 'https://foo.bar/results';
  const url = page ? `${baseUrl}&page=${page}` : baseUrl;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `failed to fetch results; status ${response.status}: ${response.statusText}`,
    );
  }

  const results = await response.json();
  const nextPage = response.headers.get('x-next-page');

  if (nextPage) {
    return results.concat(await fetchResults(nextPage));
  }

  return results;
};

```

Initially, `fetchResults` can be invoked with no specified `page` query parameter, thereby prompting it to collect all pages' results, beginning with the first page, by calling itself recursively to fetch each subsequent page:

```javascript
try {
  const allResults = await fetchResults();
} catch(err) {
  console.error(err);
}
```
