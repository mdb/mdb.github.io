---
title: "CSS3: Using Transform to Make a Cube"
date: 2011/07/15
tags:
- css3
thumbnail: ./images/thumbnails/cube_thumb.png
teaser: My quick solution to a CSS challenge.
---

CSS transforms! The following works in IE9 and above, as well as modern versions of Firefox, Safari, Chrome, and Opera. There's probably a trickier way this could be done with less markup, leveraging the <code>:before</code> and <code>:after</code> pseudo classes.

## Example

<img src="/images/blog/cube.png" />

## The HTML

``` html
<div class="cube">
  <div class="cube-side top"></div>
  <div class="cube-side left"></div>
  <div class="cube-side right"></div>
</div>
```

## The CSS

``` css
/* a container div */
div.cube {
  position:relative;
  width:200px;
  height:220px;
}

/* styles for all the cube's sides (top, left, and right) */
div.cube-side {
  width:100px;
  height:100px;
  position:absolute;
}

/* the cube's top side */
div.top {
  left:50px;
  top:10px;
  background:#612d2d;
  -moz-transform:
    rotate(60deg)
    skew(0deg, -30deg)
    scale(1, 1.15);
  -webkit-transform:
    rotate(60deg)
    skew(0deg, -30deg)
    scale(1, 1.15);
  -o-transform:
    rotate(60deg)
    skew(0deg, -30deg)
    scale(1, 1.15);
  -ie-transform:
    rotate(60deg)
    skew(0deg, -30deg)
    scale(1, 1.15);
  transform:
    rotate(60deg)
    skew(0deg, -30deg)
    scale(1, 1.15);
}

/* the cube's left side */
div.left {
  background:#b06969;
  top:90px;
  left:0px;
  -moz-transform:skew(0deg, 30deg);
  -webkit-transform:skew(0deg, 30deg);
  -o-transform:skew(0deg, 30deg);
  -ie-transform:skew(0deg, 30deg);
  transform:skew(0deg, 30deg);
}

/* the cube's right side */
div.right {
  background:#b07c7c;
  top:90px;
  right:0;
  -moz-transform:skew(0deg, -30deg);
  -webkit-transform:skew(0deg, -30deg);
  -o-transform:skew(0deg, -30deg);
  -ie-transform:skew(0deg, -30deg);
  transform:skew(0deg, -30deg);
}
```
