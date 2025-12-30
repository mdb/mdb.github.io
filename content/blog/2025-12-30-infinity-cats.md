---
title: Infinity Cats
date: 2025-12-30
tags:
- css
- illustration
- prints
thumbnail: colorful_cats_thumb.jpg
teaser: Cats forever wallpaper prints, made to order in the dimensions of your choosing. Reach out for pricing and details.
---

<style>
body {
  background-image: url('/images/blog/colorful_cats_800x800.jpg');
  background-repeat: repeat;
}

header, main {
  visibility: hidden;
}

.browser-window {
  visibility: hidden; /* uncomment to view CSS animation */
  width: 99%;
  height: 5000px;
  overflow: hidden;
  background: #f1f1f1;
  border-radius: 5px;
  position: relative;
  border: 1px solid #e1e1e1;
}

.image-container {
  border-radius: 5px;
  width: 100%;
  height: 80000px;
  background-image: url('/images/blog/colorful_cats_800x800.jpg');
  background-repeat: repeat-y;
  background-position: 0 0;
  animation: slide 200s linear infinite;
}

@keyframes slide {
  from {
    background-position: 0 100%;
  }
  to {
    background-position: 0 0; 
  }
}

.browser-window::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 25px;
  background: #e1e1e1;
  border-top-left-radius: 5px;
  border-top-right-radius: 5px;
}

.browser-window::after {
  content: "";
  position: absolute;
  top: 8px;
  left: 10px;
  width: 10px;
  height: 10px;
  background: #ff5f56; /* red */
  border-radius: 50%;
  box-shadow: 15px 0 0 #ffbd2e, /* yellow */
              30px 0 0 #27c93f; /* green */
}
</style>

<div class="browser-window">
  <div class="image-container"></div>
</div>
