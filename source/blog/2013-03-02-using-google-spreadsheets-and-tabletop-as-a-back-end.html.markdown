---
title: Using Google Spreadsheets and Tabletop.js as a Web Application Back-end
date: 2013/03/02
tags: javascript, nicar
thumbnail: pyramid_thumb.png
---

At <a href="http://ire.org/events-and-training/event/315">NICAR 2013</a>, I attended <a href="http://tasneemraja.com">Tasneem Raja</a>&#8216;s talk on <a href="http://ire.org/events-and-training/event/315/623">Smarter interactive Web projects with Google Spreadsheets and Tabletop.js</a>. Tasneem Raja is <em>Mother Jones</em>&#8216;s Interactive Editor. Tasneem outlined how <em>Mother Jones</em> uses Google Spreadsheets to power some of its interactive features.

Beyond serving as a simple, easy-to-maintain datastore and CMS, Google Spreadsheets &mdash; used in concert with <a href="https://github.com/jsoma/tabletop">Tabletop.js</a> &mdash; allows for the creation of dynamic web content in absence of  server-side processing and an application server, in effect empowering a highly scalable and remarkably simple architecture.

The following offers a simple example.

<b>1.</b> Sign into <a href="https://drive.google.com">Google Drive</a> with your Google credentials and create a new Spreadsheet titled <code>tabletop_example</code> with the following content:</p>

<img src="http://www.mikeball.us/wp-content/uploads/2013/03/tabletop_spreadsheet.png" alt="tabletop_spreadsheet" />

<b>2.</b> Click <code>File > Publish to the Web > Start Publishing</code> to publicly publish your spreadsheet.
<b>3.</b> Create a project directory with the following files and structure:</p>

```
├── index.html
└── js
    ├── app.js
    └── vendor
        └── tabletop.js
```

Grab a copy of <a href="https://github.com/jsoma/tabletop">Tabletop.js</a> to store in <code>js/vendor/tabletop.js</code>.

Set up the homepage by adding the following to index.html:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Some Site Title</title>
  </head>
  <body>
    <header>
      <h1><a href="/">Some Site Title&</a></h1>
    </header>
    <ul id="politicians"></ul>
    <script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
    <script src="js/vendor/tabletop.js"></script>
    <script src="js/app.js"></script>
  </body>
</html>
```

Retrieve the document key associated with your <code>tabletop\_example</code> spreadsheet. This can be found in the document&#8217;s URL: https://docs.google.com/spreadsheet/ccc?key=<strong>YOUR\_DOCUMENT\_KEY_APPEARS\_HERE</strong>

```javascript
$(document).ready(function () {
  Tabletop.init({
    key: 'YOUR_DOCUMENT_KEY_GOES_HERE',
    callback: function(data, tabletop) {
      var i,
          dataLength = data.length;

      for (i=0; i&<dataLength; i++) {
        $('#politicians').append(
          $('<li>', {
            text: data[i].politician + ', ' + data[i].position
          })
        );
      }
    },
    simpleSheet: true
  });
});
```

Open <code>index.html</code> in your web browser.

While the above code outlines a fairly simple example, tools like <a href="http://backbonejs.org">Backbone.js</a> provide the opportunity to layer in functionality such as URL routing, filtering, and sorting. And again, because Tabletop.js requires no application server, this solution requires no technology beyond static HTML, CSS, and JavaScript. As such, it&#8217;s highly scalable when deployed to a web server like <a href="http://nginx.org">nginx</a> or <a href="http://httpd.apache.org">Apache</a>.
