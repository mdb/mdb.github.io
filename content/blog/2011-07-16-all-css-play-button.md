---
title: "CSS3: An All-CSS, Image-less Play Button"
date: 2011-07-16
tags:
- css
- css3
- notes
thumbnail: play_thumb.jpg
teaser: I wondered if it could be done; here's a quick and dirty technique.
---

## The HTML

```html
<a class="thumb" href="/some-url">
  <img src="some-image.jpg" alt="Image" />
  <b class="play">
    <i class="wave"></i>
    <i class="arrow">Play now</i>
  </b>
</a>
```

## The CSS

```css
/* the anchor tag containing everything */
a.thumb {
  position:relative;
  width:300px;
  height:225px;
  display:block;
}

/* the black box */
b.play {
  display:block;
  position:absolute;
  width:80px;
  height:75px;
  bottom:0;
  right:0;
  background:#1a1a1a;
  text-indent:-5000px;
  overflow:hidden;
}

/* the arrow's container */
i.arrow {
  display: block;
  width: 40px;
  height: 45px;
  overflow:hidden;
  position:relative;
  margin:-30px 0 0 25px;
}

/* the arrow */
i.arrow:after {
  content:'';
  display:block;
  background:#fff;
  width:60px;
  height:65px;
  -moz-transform:
    rotate(-60deg)
    skewY(30deg);
  -webkit-transform:
    rotate(-60deg)
    skewY(30deg);
  -o-transform:
    rotate(-60deg)
    skewY(30deg);
  -ms-transform:
    rotate(-60deg)
    skewY(30deg);
  transform:
    rotate(-60deg)
    skewY(30deg);
  position:absolute;
  left:-52px;
  top:-10px;
}

/* the gradiated and curved background behind the arrow */
i.wave {
  content:'';
  display:block;
  background:-moz-linear-gradient(center top, #000000, #272727 83%, #3D3D3D 100%) repeat scroll 0 0 transparent;
  background-image:-ms-linear-gradient(center top, #000000, #272727 83%, #3D3D3D 100%) repeat scroll 0 0 transparent;
  background:-webkit-gradient(linear, center top, center bottom, from(#000), color-stop(83%, #272727), color-stop(100%, #3d3d3d));
  border-radius:80px;
  display:block;
  height:160px;
  margin-left:-45px;
  margin-top:-110px;
  width:170px;
}
```
