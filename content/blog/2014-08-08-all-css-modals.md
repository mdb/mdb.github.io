---
title: All CSS Modal Dialogs
date: 2014-08-08
tags:
- css
- css3
- ui
thumbnail: noise_collage_thumb.png
teaser: A simple example demonstrating all-CSS, no-JavaScript modal dialogs.
---

A simple technique for creating modal dialogs without the need for JavaScript.

The HTML:

```html
<a href="#modal-1">Modal dialog opener</a>

<div class="modal" id="modal-1">
  <div class='modal-content'>
    <a class="close" href="#">close</a>
    <h2>Some Heading</h2>
    <p>Some paragraph</p>
  </div>
</div>
```

The CSS:

```css
.modal {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: rgba(0,0,0,0.7);
  z-index: 99999;
  opacity: 0;
  -webkit-transition-property: opacity;
  -moz-transition-property: opacity;
  -o-transition-property: opacity;
  transition-property: opacity;

  -webkit-transition-duration: 400ms;
  -moz-transition-duration: 400ms;
  -o-transition-duration: 400ms;
  transition-duration: 400ms;

  -webkit-transition-timing-function: ease-in;
  -moz-transition-timing-function: ease-in;
  -o-transition-timing-function: ease-in;
  transition-timing-function: ease-in;

  pointer-events: none;
}

.modal:target {
  opacity: 1;
  pointer-events: auto;
}

.modal a.close {
  position: absolute;
  right: 10px;
}

.modal div.modal-content {
  padding: 10px;
  position: relative;
  margin: 5% auto 0 auto;
  width: 60%;
  overflow: hidden;
  background: #fff;
}
```

<a class="modal-trigger" href="#modal-1">View demo &raquo;</a>

<div class="modal" id="modal-1">
  <div class='modal-content'>
    <a class="close" href="#">close</a>
    <h2>Some Heading</h2>
    <p>Some paragraph</p>
  </div>
</div>
