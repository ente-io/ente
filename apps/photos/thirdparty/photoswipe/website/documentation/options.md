---

layout: default

title: PhotoSwipe Options

h1_title: Options

description: Complete list of PhotoSwipe options (including PhotoSwipeUI_Default options).

addjs: true

canonical_url: http://photoswipe.com/documentation/options.html

buildtool: true

markdownpage: true

---

Options are added in key-value pairs and passed as an argument to `PhotoSwipe` constructor, e.g.:

```javascript
var options = {
	index: 3,
	escKey: false,

	// ui option
	timeToIdle: 4000
};
var gallery = new PhotoSwipe( someElement, PhotoSwipeUI_Default, someItems, options);
gallery.init();

// Note that options object is cloned during the initialization.
// But you can access it via `gallery.options`.
// For example, to dynamically change `escKey`:
gallery.options.escKey = false;

// `options.escKey = false` will not work

```


## Core

### `index` <code class="default">integer</code> <code class="default">0</code>

Start slide index. `0` is the first slide. Must be integer, not a string.

### `getThumbBoundsFn` <code class="default">function</code> <code class="default">undefined</code>

Function should return an object with coordinates from which initial zoom-in animation will start (or zoom-out animation will end). 

Object should contain three properties: `x` (X position, relative to document), `y` (Y position, relative to document), `w` (width of the element). Height will be calculated automatically based on size of large image. For example if you return `{x:0,y:0,w:50}` zoom animation will start in top left corner of your page.

Function has one argument - `index` of the item that is opening or closing.

In non-modal mode, the template's position relative to the viewport should be subtracted from `x` and `y`. Look at [the FAQ](faq.html#inline-gallery) for more information.

Example that calculates position of thumbnail: 

```javascript
getThumbBoundsFn: function(index) {

	// find thumbnail element
	var thumbnail = document.querySelectorAll('.my-gallery-thumbnails')[index];
	
	// get window scroll Y
	var pageYScroll = window.pageYOffset || document.documentElement.scrollTop; 
	// optionally get horizontal scroll

	// get position of element relative to viewport
	var rect = thumbnail.getBoundingClientRect(); 
	
	// w = width
	return {x:rect.left, y:rect.top + pageYScroll, w:rect.width};


	// Good guide on how to get element coordinates:
	// http://javascript.info/tutorial/coordinates
}
```

If dimensions of your small thumbnail don't match dimensions of large image, consider enabling zoom+fade transition. You can do this by adding option `showHideOpacity:true` (try adding it to [above CodePen](http://codepen.io/dimsemenov/pen/ZYbPJM) to test how it looks). Or disable transition entirely by adding `hideAnimationDuration:0, showAnimationDuration:0`. [More info about this in FAQ](faq.html#different-thumbnail-dimensions).

If you want to "hide" small thumbnail during the animation use `opacity:0`, not `visibility:hidden` or `display:none`. Don't force Paint and Layout at the beginning of the animation to avoid lag.


### `showHideOpacity` <code class="default">boolean</code> <code class="default">false</code>

If set to `false`: background `opacity` and image `scale` will be animated (image opacity is always 1). 
If set to `true`: root PhotoSwipe element `opacity` and image `scale` will be animated.

To enable just `opacity` transition (without `scale`), do not define `getThumbBoundsFn` option.

### `showAnimationDuration` <code class="default">integer</code> <code class="default">333</code>

Initial zoom-in transition duration in milliseconds. Set to `0` to disable.
Besides this JS option, you need also to change transition duration in PhotoSwipe CSS file:

```css
.pswp--animate_opacity,
.pswp__bg,
.pswp__caption,
.pswp__top-bar,
.pswp--has_mouse .pswp__button--arrow--left,
.pswp--has_mouse .pswp__button--arrow--right{
	-webkit-transition: opacity 333ms cubic-bezier(.4,0,.22,1);
	transition: opacity 333ms cubic-bezier(.4,0,.22,1);
}
```

If you're using Sass, you just need to change transition-duration variables in [_main-settings.scss](https://github.com/dimsemenov/PhotoSwipe/blob/master/src/css/_main-settings.scss).


### `hideAnimationDuration` <code class="default">integer</code> <code class="default">333</code>

The same as the previous option, just for closing (zoom-out) transition. After PhotoSwipe is opened `pswp--open` class will be added to the root element, you may use it to apply different transition duration in CSS.


### `bgOpacity` <code class="default">number</code> <code class="default">1</code>

Background (`.pswp__bg`) opacity. Should be a number from 0 to 1, e.g. `0.7`. This style is defined via JS, not via CSS, as this value is used for a few gesture-based transitions.


### `spacing` <code class="default">number</code> <code class="default">0.12</code>

Spacing ratio between slides. For example, `0.12` will render as a 12% of sliding viewport width (rounded). 


### `allowPanToNext` <code class="default">boolean</code> <code class="default">true</code>

Allow swipe navigation to next/prev item when current item is zoomed. Option is always `false` on devices that don't have hardware touch support.


### `maxSpreadZoom` <code class="default">number</code> <code class="default">2</code>

Maximum zoom level when performing spread (zoom) gesture. `2` means that image can be zoomed 2x from original size. Try to avoid huge values here, as too big image may cause memory issues on mobile (especially on iOS).


### `getDoubleTapZoom` <code class="default">function</code>

Function should return zoom level to which image will be zoomed after double-tap gesture, or when user clicks on zoom icon, or mouse-click on image itself. If you return `1` image will be zoomed to its original size.

Default value:

```javascript
getDoubleTapZoom: function(isMouseClick, item) {

	// isMouseClick          - true if mouse, false if double-tap
	// item                  - slide object that is zoomed, usually current
	// item.initialZoomLevel - initial scale ratio of image
	// 						   e.g. if viewport is 700px and image is 1400px,
	// 						   		initialZoomLevel will be 0.5

	if(isMouseClick) {

		// is mouse click on image or zoom icon
		
		// zoom to original
		return 1;

		// e.g. for 1400px image:
		// 0.5 - zooms to 700px
		// 2   - zooms to 2800px
		
	} else {

		// is double-tap
		
		// zoom to original if initial zoom is less than 0.7x,
		// otherwise to 1.5x, to make sure that double-tap gesture always zooms image
		return item.initialZoomLevel < 0.7 ? 1 : 1.5;
	}
}
```

Function is called each time zoom-in animation is initiated. So feel free to return different values for different images based on their size or screen DPI.




### `loop` <code class="default">boolean</code> <code class="default">true</code>

Loop slides when using swipe gesture. If set to `true` you'll be able to swipe from last to first image. Option is always `false` when there are less than 3 slides.

This option has no relation to arrows navigation. Arrows loop is turned on permanently. You can modify this behavior by making custom UI.


### `pinchToClose` <code class="default">boolean</code> <code class="default">true</code>

Pinch to close gallery gesture. The gallery’s background will gradually fade out as the user zooms out. When the gesture is complete, the gallery will close.


### `closeOnScroll` <code class="default">boolean</code> <code class="default">true</code>

Close gallery on page scroll. Option works just for devices without hardware touch support.


### `closeOnVerticalDrag` <code class="default">boolean</code> <code class="default">true</code>

Close gallery when dragging vertically and when image is not zoomed. Always `false` when mouse is used.
 

### `mouseUsed` <code class="default">boolean</code> <code class="default">false</code>

Option allows you to predefine if mouse was used or not. Some PhotoSwipe feature depend on it, for example default UI left/right arrows will be displayed only after mouse is used. If set to `false`, PhotoSwipe will start detecting when mouse is used by itself, `mouseUsed` event triggers when mouse is found.


### `escKey` <code class="default">boolean</code> <code class="default">true</code>

`esc` keyboard key to close PhotoSwipe. Option can be changed dynamically (`yourPhotoSwipeInstance.options.escKey = false;`).


### `arrowKeys` <code class="default">boolean</code> <code class="default">true</code>

Keyboard left or right arrow key navigation. Option can be changed dynamically (`yourPhotoSwipeInstance.options.arrowKeys = false;`).


### `history` <code class="default">boolean</code> <code class="default">true</code>

If set to `false` disables history module (back button to close gallery, unique URL for each slide). You can also just exclude `history.js` module from your build.


### `galleryUID` <code class="default">integer</code> <code class="default">1</code>

Gallery unique ID. Used by History module when forming URL. For example, second picture of gallery with UID 1 will have URL: `http://example.com/#&gid=1&pid=2`.


### <a name="galleryPIDs"></a> `galleryPIDs` <code class="default">boolean</code> <code class="default">false</code>

Enables custom IDs for each slide object that are used when forming URL. If option set set to `true`, slide objects must have `pid` (picture identifier) property that can be a string or an integer. For example:

```js
var slides = [
	{
		src: 'path/to/1.jpg',
		w:500,
		h:400,
		pid: 'image-one'
	},
	{
		src: 'path/to/2.jpg',
		w:300,
		h:700,
		pid: 'image-two'
	},

	... 
];
```

... second slide will have URL `http://example.com/#&gid=1&pid=image-two`.

Read more about how to implement custom PID in [the FAQ section](faq.html#custom-pid-in-url).


### `errorMsg` <code class="default">string</code>

Error message when image was not loaded. `%url%` will be replaced by URL of image.

Default value:

```html
<div class="pswp__error-msg"><a href="%url%" target="_blank">The image</a> could not be loaded.</div>
```


### `preload` <code class="default">array</code> <code class="default">[1,1]</code>

Lazy loading of nearby slides based on direction of movement. Should be an array with two integers, first one - number of items to preload before current image, second one - after the current image. E.g. if you set it to [1,3], it'll load 1 image before the current, and 3 images after current. Values can not be less than 1.


### `mainClass` <code class="default">string</code> <code class="default">undefined</code>

String with name of class that will be added to root element of PhotoSwipe (`.pswp`). Can contain multiple classes separated by space.


### `getNumItemsFn` <code class="default">function</code>

Function that should return total number of items in gallery. By default it returns length of slides array. Don't put very complex code here, function is executed very often.

### `focus` <code class="default">boolean</code> <code class="default">true</code>

Will set focus on PhotoSwipe element after it's open.

### `isClickableElement` <code class="default">function</code>

Default value:

```javascript
isClickableElement: function(el) {
	return el.tagName === 'A';
}
```

Function should check if the element (`el`) is clickable. If it is &ndash; PhotoSwipe will not call `preventDefault` and `click` event will pass through. Function should be as light is possible, as it's executed multiple times on drag start and drag release.

### `modal` <code class="default">boolean</code> <code class="default">true</code>

Controls whether PhotoSwipe should expand to take up the entire viewport. If false, the PhotoSwipe element will take the size of the positioned parent of the template. Take a look at [the FAQ](faq.html#inline-gallery) for more information.

## Default UI Options

Options for `PhotoSwipeUI_Default` (`dist/ui/photoswipe-ui-default.js`) are added the same way and to the same object as core options.

```javascript
// Size of top & bottom bars in pixels,
// "bottom" parameter can be 'auto' (will calculate height of caption)
// option applies only when mouse is used, 
// or width of screen is more than 1200px
// 
// (Also refer to `parseVerticalMargin` event)
barsSize: {top:44, bottom:'auto'}, 

// Adds class pswp__ui--idle to pswp__ui element when mouse isn't moving for 4000ms
timeToIdle: 4000,

// Same as above, but this timer applies when mouse leaves the window
timeToIdleOutside: 1000,

// Delay until loading indicator is displayed
loadingIndicatorDelay: 1000,

// Function builds caption markup
addCaptionHTMLFn: function(item, captionEl, isFake) {
	// item      - slide object
	// captionEl - caption DOM element
	// isFake    - true when content is added to fake caption container
	// 			   (used to get size of next or previous caption)
	
	if(!item.title) {
		captionEl.children[0].innerHTML = '';
		return false;
	}
	captionEl.children[0].innerHTML = item.title;
	return true;
},

// Buttons/elements
closeEl:true,
captionEl: true,
fullscreenEl: true,
zoomEl: true,
shareEl: true,
counterEl: true,
arrowEl: true,
preloaderEl: true,

// Tap on sliding area should close gallery
tapToClose: false,

// Tap should toggle visibility of controls
tapToToggleControls: true,

// Mouse click on image should close the gallery,
// only when image is smaller than size of the viewport
clickToCloseNonZoomable: true,

// Element classes click on which should close the PhotoSwipe.
// In HTML markup, class should always start with "pswp__", e.g.: "pswp__item", "pswp__caption".
// 
// "pswp__ui--over-close" class will be added to root element of UI when mouse is over one of these elements
// By default it's used to highlight the close button.
closeElClasses: ['item', 'caption', 'zoom-wrap', 'ui', 'top-bar'], 

// Separator for "1 of X" counter
indexIndicatorSep: ' / ',


{% raw %}
// Share buttons
// 
// Available variables for URL:
// {{url}}             - url to current page
// {{text}}            - title
// {{image_url}}       - encoded image url
// {{raw_image_url}}   - raw image url
shareButtons: [
	{id:'facebook', label:'Share on Facebook', url:'https://www.facebook.com/sharer/sharer.php?u={{url}}'},
	{id:'twitter', label:'Tweet', url:'https://twitter.com/intent/tweet?text={{text}}&url={{url}}'},
	{id:'pinterest', label:'Pin it', url:'http://www.pinterest.com/pin/create/button/?url={{url}}&media={{image_url}}&description={{text}}'},
	{id:'download', label:'Download image', url:'{{raw_image_url}}', download:true}
],
{% endraw %}

// Next 3 functions return data for share links
// 
// functions are triggered after click on button that opens share modal,
// which means that data should be about current (active) slide
getImageURLForShare: function( shareButtonData ) {
	// `shareButtonData` - object from shareButtons array
	// 
	// `pswp` is the gallery instance object,
	// you should define it by yourself
	// 
	return pswp.currItem.src || '';
},
getPageURLForShare: function( shareButtonData ) {
	return window.location.href;
},
getTextForShare: function( shareButtonData ) {
	return pswp.currItem.title || '';
},

// Parse output of share links
parseShareButtonOut: function(shareButtonData, shareButtonOut) {
	// `shareButtonData` - object from shareButtons array
	// `shareButtonOut` - raw string of share link element
	return shareButtonOut;
}
```

Know how this page can be improved? Found a typo? [Suggest an edit!](https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/responsive-images.md)

<iframe src="http://ghbtns.com/github-btn.html?user=dimsemenov&amp;repo=photoswipe&amp;type=watch&amp;count=true&amp;size=large" allowtransparency="true" frameborder="0" scrolling="0" width="155" height="30" style=""></iframe>


