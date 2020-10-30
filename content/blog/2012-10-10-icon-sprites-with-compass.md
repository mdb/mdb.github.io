---
title: Icon Sprites with Compass
date: 2012-10-10
tags:
- compass
- scss
- css
thumbnail: scallops_thumb.png
teaser: CSS authoring can hurt. Compass abstracts away the pain.
---

Manually creating sprite images is time-consuming and subject to human error. The corresponding CSS is often verbose and largely repetitive.

<b>Solution</b>: Leverage <a href="http://compass-style.org/">Compass</a>'s spriting and looping features.

Example: You have an icon set of 20 10x10px individual .png files. Their file names follow the convention icon\_1.png, icon\_2.png, and icon\_3.png through icon\_20.png.

## Step 1: Install compass

```bash
gem install compass
```

## Step 2: Create a compass project

```bash
compass create your_project_name
```

## Step 3: Configure compass spriting

In the case of the aforementioned, example, you&#8217;ll want to configure compass to build a sprite from the directory containing the icons. In this case, I created an <code>images/sprites/icons</code> directory.

Place the icons in an <code>images/sprites/icons/</code> directory within your compass project.

Create and/or edit your compass project&#8217;s <code>scss/_sprite.scss</code> file to build sprites from the newly created <code>images/sprites/icons/</code> directory. Add the following:

```scss
$bit24-layout: smart
$bit24-sprite-dimensions: true
@import "images/sprites/icons/*.png"
```

## Step 4: Write SCSS

The SCSS:

```scss
@import "_sprite";
.icon {
  width: 20px;
  height: 20px;
  display: block;
  text-indent: -5000px;

  @for $i from 0 through 20 {
    &.icon-#{$i} {
      @include icons-sprite(icon_#{$i});
    }
  }
}
```

The resultant compiled CSS:

```css
// line 418, sprites/icons/*.png
.icons-sprite, .icon.icon-0, .icon.icon-1, .icon.icon-2, .icon.icon-3, .icon.icon-4, .icon.icon-5, .icon.icon-6, .icon.icon-7, .icon.icon-8, .icon.icon-9, .icon.icon-10, .icon.icon-11, .icon.icon-12, .icon.icon-13, .icon.icon-14, .icon.icon-15, .icon.icon-16, .icon.icon-17, .icon.icon-18, .icon.icon-19, .icon.icon-20 {
  background: url('/images/sprites/icons-sda260d590b.png') no-repeat;
}
.icon {
  width: 20px;
  height: 20px;
  display: block;
  text-indent: -5000px;
}
.icon.icon-0 {
  background-position: 0 -260px;
}
.icon.icon-1 {
  background-position: 0 -312px;
}
.icon.icon-2 {
  background-position: 0 -416px;
}
.icon.icon-3 {
  background-position: 0 -468px;
}
.icon.icon-4 {
  background-position: 0 -572px;
}
.icon.icon-5 {
  background-position: 0 -728px;
}
.icon.icon-6 {
  background-position: 0 -676px;
}
.icon.icon-7 {
  background-position: 0 -624px;
}
.icon.icon-8 {
  background-position: 0 -1144px;
}
.icon.icon-9 {
  background-position: 0 -1300px;
}
.icon.icon-10 {
  background-position: 0 -988px;
}
.icon.icon-11 {
  background-position: 0 -1248px;
}
.icon.icon-12 {
  background-position: 0 -1196px;
}
.icon.icon-13 {
  background-position: 0 -1664px;
}
.icon.icon-14 {
  background-position: 0 -1456px;
}
.icon.icon-15 {
  background-position: 0 0;
}
.icon.icon-16 {
  background-position: 0 -780px;
}
.icon.icon-17 {
  background-position: 0 -364px;
}
.icon.icon-18 {
  background-position: 0 -1508px;
}
.icon.icon-19 {
  background-position: 0 -1560px;
}
.icon.icon-20 {
  background-position: 0 -1716px;
}
```

## Step 5: Write HTML
Now, the icon sprite styles can be leveraged in HTML like so:

```html
<b class="icon icon-1">Some icon</b>
```
