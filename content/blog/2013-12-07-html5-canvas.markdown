---
title: HTML5 Canvas
date: 2013-12-07
tags:
- javascript
- html5
published: false
thumbnail: ./images/thumbnails/default_thumb.gif
---

## Drawing rectangles

Unlike SVG, <code>canvas</code> only supports one primitive shape: rectangles. All other shapes must be created by combining one or more paths.

Three functions that draw rectangles:

```javascript
// Draws a filled rectangle.
fillRect(x, y, width, height)

//Draws a rectangular outline.
strokeRect(x, y, width, height)

//Clears the specified rectangular area, making it fully transparent.
clearRect(x, y, width, height)
```

## Drawing paths

1. create the path (<code>beginPath()</code>)
2. use drawing commands to draw into the path
3. close the path
4. stroke or fill the path to render it

```javascript
// Creates a new path. Once created, future drawing commands are directed into the path and used to build the path up.
beginPath()

// Closes the path so that future drawing commands are once again directed to the context.
closePath()

// Draws the shape by stroking its outline.
stroke()

// Draws a solid shape by filling the path's content area.
fill()
```
