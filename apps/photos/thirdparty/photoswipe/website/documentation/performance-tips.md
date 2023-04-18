---

layout: default

title: PhotoSwipe Performance Tips

h1_title: Performance Tips

description: Suggestions on how to make gallery faster.

addjs: true

canonical_url: http://photoswipe.com/documentations/performance-tips.html

buildtool: true

markdownpage: true

---

## Animations

- Animation performance dramatically depends on the size of an image. The smaller image &ndash; the smoother animation. So don't be lazy and [serve responsive images](responsive-images.html), or at least don't serve images larger than 1200x1200 for phones.
- Don't do anything during the animations that can cause Paint or Layout. Don't append new elements to the DOM. Don't change `display` or `visibility`. Don't breath. You can only change `transform` and `opacity`. Delay all your changes after animation ends &ndash; use events: `beforeChange` (slide switched), `initialZoomInEnd` (initial zoom in animation ended) and `initialZoomOutEnd` (initial zoom out animation ended).
- Try to avoid complex `:hover` and `:active` effects on thumbnails that open PhotoSwipe if you have zoom-in/out animation enabled (apply the first rule). 
- Make sure that you don't have complex styles on UI over PhotoSwipe sliding area. For example, `text-shadow` on caption text can cause issues.

If you followed above steps and performance of your gallery differs from [PhotoSwipe home page](http://photoswipe.com), start isolating PhotoSwipe on page by excluding all JS/CSS/HTML code not related to it. Make sure that you don't have any kind of banner rotators that continuously run some animation behind the PhotoSwipe. 

If it doesn't work fast even after you isolated PhotoSwipe &ndash; open an [issue on GitHub](https://github.com/dimsemenov/PhotoSwipe/issues) and provide a link to [reduced test case](http://css-tricks.com/reduced-test-cases/).

## Including Files

- Default PhotoSwipe UI has `png` and `svg` sprite. By default, it's loaded only after PhotoSwipe is opened. To make controls appear instantly, you may merge gallery sprite with your site "main" sprite, or preload it via CSS.
- Defer the loading of PhotoSwipe JS file(s) if gallery is not the main feature of your page. 
- Combine JS, minify and combine CSS files.

Know how this page can be improved? [Suggest an edit!](https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/responsive-images.md)

<iframe src="http://ghbtns.com/github-btn.html?user=dimsemenov&amp;repo=photoswipe&amp;type=watch&amp;count=true&amp;size=large" allowtransparency="true" frameborder="0" scrolling="0" width="155" height="30" style=""></iframe>