---
title: Deploying an Express App to Heroku
date: 2012/10/22
tags: javascript, node.js, express, heroku
thumbnail: triangle_thumb.png
teaser: A beginner's tutorial in deploying a Node.js app to Heroku.
---

Some coworkers expressed interest in deploying <a href="http://expressjs.com">Express</a> apps to <a href="http://heroku.com">Heroku</a>. These instructions seek to provide a basic overview, though Heroku offers much more robust documentation in its <a href="https://devcenter.heroku.com">dev center</a>.

Step 1: Create a <a href="https://api.heroku.com/signup">Heroku</a> account.

Step 2: Install the <a href="https://toolbelt.herokuapp.com">Heroku Toolbelt</a>, which includes the Heroku command line client, Git, and Foreman.</li>

Step 3: Log in by entering the following in the command line:

```
heroku login
```

Step 4: Install <a href="http://nodejs.org">Node.js</a>.

Step 5: Create an Express app.

Let&#8217;s call it <code>heroku-demo</code>:

```
mkdir heroku-demo
```

Define the application dependencies via a heroku-demo/package.json file:

```javascript
{
 "name": "heroku-demo",
 "description": "Basic Express.js/Heroku demo",
 "version": "0.0.1",
 "private": true,
 "dependencies": {
   "express": "3.x"
  }
}
```

Install the package:

```
npm install
```

Set up the app via a <code>heroku-demo/app.js</code> file:

```javascript
var express = require("express");
var app = express();

// Set up a URL route
app.get("/", function(req, res) {
 res.send("Heroku Demo!");
});

// bind the app to listen for connections on a specified port
var port = process.env.PORT || 3000;
app.listen(port);

// Render some console log output
console.log("Listening on port " + port);
```

Now, you can run your app locally and view it in your browser at <code>http://localhost:3000</code>:

```
node app.js
```

Step 6: Declare your app&#8217;s process types with a <code>heroku-demo/Procfile</code> so that it can run with <a href="https://github.com/ddollar/foreman">Foreman</a>:

```
web: node app.js
```

This declares a &#8220;web&#8221; process, as well as the command needed to run it. You can test that your Procfile/Foreman works:</p>

```
foreman start
```

Step 7: Make <code>heroku-demo</code> a Git repository:

```
git init
git add .
git commit -m "Initial commit"
```

Step 8: Deploy heroku-demo to Heroku.

Create a Heroku app:

```
heroku create
```

Deploy the code to Heroku:

```
git push heroku master
```

Step 9: View your Heroku-hosted app in your web browser:

```
heroku open
```

## Some Additional Heroku CLI Tips

Make your app available at a custom newname.herokuapp.com subdomain:

```
heroku apps:rename newname
```

You can also use custom domains. See the <a href="https://devcenter.heroku.com/articles/custom-domains">Heroku documentation</a>.

View environment variables:

```
heroku config
```

<a href="https://devcenter.heroku.com/articles/config-vars">More Heroku environment variable documentation</a>.

Add environment variables:

```
heroku config:add NODE_ENV=production
```

View logs:

```
heroku logs
```

View running processes:

```
heroku ps
```

Learn more about the Heroku command line client:

```
heroku help
```
