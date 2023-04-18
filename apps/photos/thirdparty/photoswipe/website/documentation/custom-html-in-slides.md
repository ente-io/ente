---

layout: default

title: Custom HTML Content in PhotoSwipe Slides 

h1_title: Custom HTML Content in Slides

description: How to add custom HTML in PhotoSwipe slides, like ads or list of related galleries.

addjs: true

canonical_url: http://photoswipe.com/documentation/custom-html-in-slides.html

buildtool: true

markdownpage: true

---

To make PhotoSwipe display HTML content in slides you need to define `html` property in slide object. It should contain HTML string or DOM element object.

```javascript

var items = [
	// slide 1 with HTML
	{
		html: '<div><h1>Any HTML <a href="http://example.com">content</a></h1></div>'
	},

	// slide 2 with image
	{
		src: 'path/to/image.jpg',
		w:600,
		h:200
	}
];


// initialise as usual
var gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);

// You don't necessarily need to have "html" property in slide object initially.
// You may create it dynamically in gettingData event:
/*
	gallery.listen('gettingData', function(index, item) {
		if(index === 3) {
			item.html = '<div>Dynamically generated HTML ' + Math.random() + '</div>';
		}

	});
*/

// Note that init() method is called after gettingData event is bound
gallery.init();
```

Additional important notes:

- To avoid conflicts with third-party modules, slide that has `html` property, should not have `src` (image) property.
- PhotoSwipe is designed for images, not as a scroller of text content. Use "custom HTML" feature as an addition, for example for slide with related galleries, an introductory slide, or advertisements BETWEEN images.
- It's strongly not recommended to add video or audio elements using this method (including YouTube, Vimeo etc. iframes). As HTML5 video blocks touch events over it in many mobile browsers (user won't be able to swipe it). If you really need to have video in PhotoSwipe, you may add it as modal that appears when user taps on current slide, you can dynamically create modal in DOM and append it after `.pswp__scroll-wrap` element.
- If you have initial zoom-in/zoom-out transition enabled, PhotoSwipe will automatically disable it if current slide has `html`, simple fade transition will be used instead. 
- By default PhotoSwipe will allow click event just on links (`<a>`) and their child elements. To change this behavior look into `isClickableElement` option or `preventDragEvent` event.
- Zoom of HTML slides is not supported, yet. 

Example:

<div class="codepen-embed">
	<p data-height="600" data-theme-id="10447" data-slug-hash="MYexrm" data-default-tab="result" data-user="dimsemenov" class='codepen'>
		<a href="http://codepen.io/dimsemenov/pen/MYexrm/" target="_blank"><strong>View example on CodePen &rarr;</strong></a>
	</p>
</div>

Tip: you may download the example from CodePen to play with it locally (`Edit on CodePen` -> `Share` -> `Export .zip`).

Know how this page can be improved? [Suggest an edit!](https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/custom-html-in-slides.md)


