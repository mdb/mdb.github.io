---
title: Using the civic-info Node.js Module to Get Voter and Election Info
date: 2012/11/08
tags: javascript, node.js, civi-info, opendata
thumbnail: vote_thumb.png
teaser: A quick tutorial in using a simple NPM module I built.
---

<p>Inspired by election apps like <a href="https://github.com/joannecheng/vote">vote</a>, I wrote <a href="http://github.com/mdb/civic-info.js">civic-info.js</a>, a simple Node.js module to interface with Google&#8217;s <a href="https://developers.google.com/civic-information">Civic Info API</a>.<br />
## Getting Started</h4>

<b>1.</b> Secure a Google API key.
<b>2.</b> Install civic-info:

```
npm install civic-info
```

<b>3.</b> Require and instantiate civic-info with your Google API key:

```javascript
var civicInfo = require("civic-info")({apiKey: "YOUR KEY"});
```

Alteratively, you can set a <code>GOOGLE\_API\_KEY</code> environment variable and instantiate like so:

```javascript
var civicInfo = require("civic-info")();
```

## Examples
Get election info and election IDs:

```javascript
civicInfo.elections(function(data) {
  console.log(data);
});
```

Resulting response:

```javascript
{
  kind: 'civicinfo#electionsQueryResponse',
  elections:
    [ {
      id: '2000',
      name: 'VIP Test Election',
      electionDay: '2013-06-06'
    } ]
}
```

Get voter information such as polling places, contests, candidates, etc. surrounding an election whose electionID is &#8217;4000&#8242; for a voter who lives at 1500 Market Street in Philadelphia:

```javascript
civicInfo.voterInfo({electionID: '4000', address: '1500 Market Street, Philadelphia, PA'}, function(data) {
  console.log(data);
});
```
