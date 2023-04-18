---

layout: default

title: PhotoSwipe API

h1_title: API

description: Public methods, properties and events of PhotoSwipe JavaScript image gallery.

addjs: true

canonical_url: http://photoswipe.com/documentation/api.html

buildtool: true

markdownpage: true

---

All methods and properties listed on this page are public. If you want to take a look at example of what API can do, take a look in [source of default PhotoSwipe UI](https://github.com/dimsemenov/PhotoSwipe/blob/master/src/js/ui/photoswipe-ui-default.js).

You can get PhotoSwipe instance object during the initialization, e.g.:

```javascript
var photoswipeInstance = new PhotoSwipe( /* ... */ );
```

## Methods

```javascript
var pswp = new PhotoSwipe( /* ... */ );

// Initialize and open gallery
// (you can bind events before this method)
pswp.init();

// Go to slide by index
// @param {int} `index`
pswp.goTo(index);

// Go to the next slide
pswp.next();

// Go to the previous slide
pswp.prev();

// Update gallery size
// @param  {boolean} `force` If you set it to `true`, 
// 							size of the gallery will be updated 
// 							even if viewport size hasn't changed.
pswp.updateSize(force);

// Close gallery
pswp.close();

// Destroy gallery,
// automatically called after close() 
pswp.destroy()

// Zoom current slide to (optionally with animation)
// @param  {number}   `destZoomLevel` Destination scale number. 1 - original.  
// 								     pswp.currItem.fitRatio - image will fit into viewport.
// @param  {object}   `centerPoint`   Object of x and y coordinates, relative to viewport.
// @param  {int}      `speed`         Animation duration. Can be 0.
// @param  {function} `easingFn`      Easing function (optional). Set to false to use default easing.
// @param  {function} `updateFn`      Function will be called on each update frame. (optional)
//
// Example below will 2x zoom to center of slide:
// pswp.zoomTo(2, {x:pswp.viewportSize.x/2,y:pswp.viewportSize.y/2}, 2000, false, function(now) {
// 		
// });
pswp.zoomTo(destZoomLevel, centerPoint, speed, easingFn, updateFn);

// Apply zoom and pan to the current slide
// 
// @param   {number} `zoomLevel`
// @param   {int}    `panX`
// @param   {int}    `panY`
// 
// For example: `pswp.applyZoomPan(1, 0, 0)`
// will zoom current image to the original size
// and will place it on top left corner
// 
// 
pswp.applyZoomPan(zoomLevel, panX, panY);
```

## Properties

```javascript

// current slide object
pswp.currItem

// items array (slides, images)
pswp.items

// size of sliding viewport
pswp.viewportSize

// object holds all functions from framework
// framework-bridge.js
pswp.framework

// UI object (e.g. PhotoSwipeUI_Default instance)
pswp.ui

// background element (pswp__bg)
pswp.bg

// container element (pswp__container)
pswp.container

// options
pswp.options



// Even though methods below aren't technically properties, we list them here:

// current item index (int)
pswp.getCurrentIndex();

// total number of items
pswp.options.getNumItemsFn()

// current zoom level (number)
pswp.getZoomLevel();

// one (or more) pointer is used
pswp.isDragging();

// two (or more) pointers are used
pswp.isZooming();

// `true` when transition between is running (after swipe)
pswp.isMainScrollAnimating();
```

## Events

PhotoSwipe uses very simple Event/Messaging system. It has two methods `shout` (triggers event) and `listen` (handles event). For now there is no method to unbind listener, but all of them are cleared when PhotoSwipe is closed.

```javascript
var pswp = new PhotoSwipe(/* ... */);

// Listen for "helloWorld" event
pswp.listen('helloWorld', function(name) {
	alert('Name is: ' + name);
});

// Trigger "helloWorld" event
pswp.shout('helloWorld', 'John' /* you may pass more arguments */);
```

Available events:

```javascript

// Before slides change
// (before the content is changed, but after navigation)
// Update UI here (like "1 of X" indicator)
pswp.listen('beforeChange', function() { });

// After slides change
// (after content changed)
pswp.listen('afterChange', function() { });

// Image loaded
pswp.listen('imageLoadComplete', function(index, item) { 
	// index - index of a slide that was loaded
	// item - slide object
});

// Viewport size changed
pswp.listen('resize', function() { });

// Triggers when PhotoSwipe "reads" slide object data,
// which happens before content is set, or before lazy-loading is initiated.
// Use it to dynamically change properties
pswp.listen('gettingData', function(index, item) {
	// index - index of a slide that was loaded
	// item - slide object

	// e.g. change path to the image based on `something`
	if( something ) {
		item.src = item.something;
	} else {
		item.src = item.somethingElse;
	}
});

// Mouse was used (triggers only once)
pswp.listen('mouseUsed', function() { });


// Opening zoom in animation starting
pswp.listen('initialZoomIn', function() { });

// Opening zoom in animation finished
pswp.listen('initialZoomInEnd', function() { });

// Closing zoom out animation started
pswp.listen('initialZoomOut', function() { });

// Closing zoom out animation finished
pswp.listen('initialZoomOutEnd', function() { });


// Allows overriding vertical margin for individual items
pswp.listen('parseVerticalMargin', function(item) { 
	// For example:
	var gap = item.vGap;

	gap.top = 50; // There will be 50px gap from top of viewport
	gap.bottom = 100; // and 100px gap from the bottom
})

// Gallery starts closing
pswp.listen('close', function() { });

// Gallery unbinds events
// (triggers before closing animation)
pswp.listen('unbindEvents', function() { });

// After gallery is closed and closing animation finished.
// Clean up your stuff here.
pswp.listen('destroy', function() { });

// Called when the page scrolls.
// The callback is passed an offset with properties {x: number, y: number}.
//
// PhotoSwipe uses the offset to determine the top-left of the template,
// which by default is the top-left of the viewport. When using modal: false,
// you should listen to this event (before calling .init()) and modify the offset
// with the template's getBoundingClientRect().
//
// Look at the "Implementing inline gallery display" FAQ section for more info.
pswp.listen('updateScrollOffset', function(_offset) {
    var r = gallery.template.getBoundingClientRect();
    _offset.x += r.left;
    _offset.y += r.top;
});

// PhotoSwipe has a special event called pswpTap.
// It's dispatched using default JavaScript event model.
// So you can, for example, call stopPropagation on it.
// pswp.framework.bind - is a shorthand for addEventListener
pswp.framework.bind( pswp.scrollWrap /* bind on any element of gallery */, 'pswpTap', function(e) {
    console.log('tap', e, e.detail);
    // e.detail.origEvent  // original event that finished tap (e.g. mouseup or touchend)
    // e.detail.target // e.target of original event
    // e.detail.releasePoint // object with x/y coordinates of tap
    // e.detail.pointerType // mouse, touch, or pen
});

// Allow to call preventDefault on down and up events
pswp.listen('preventDragEvent', function(e, isDown, preventObj) {
	// e - original event
	// isDown - true = drag start, false = drag release

	// Line below will force e.preventDefault() on:
	// touchstart/mousedown/pointerdown events
	// as well as on:
	// touchend/mouseup/pointerup events
	preventObj.prevent = true;
});



// Default UI events
// -------------------------

// Share link clicked
pswp.listen('shareLinkClick', function(e, target) { 
	// e - original click event
	// target - link that was clicked

	// If `target` has `href` attribute and 
	// does not have `download` attribute - 
	// share modal window will popup
});


```

## Adding slides dynamically

To add, edit, or remove slides after PhotoSwipe is opened, you just need to modify the `items` array. For example, you can push new slide objects into the `items` array:

```javascript
pswp.items.push({
    src: "path/to/image.jpg", 
    w:1200,
    h:500 
});
```

If you changed slide that is CURRENT, NEXT or PREVIOUS (which you should try to avoid) &ndash; you need to call method that will update their content:

```javascript
// sets a flag that slides should be updated
pswp.invalidateCurrItems();
// updates the content of slides
pswp.updateSize(true);
```

Otherwise, you don't need to do anything else. Except, maybe, calling `pswp.ui.update()` if you want some parts of default UI to update (e.g. "1 of X" counter). Also note:

- You can't reassign whole array, you can only modify it (e.g. use `splice` to remove elements).
- If you're going to remove current slide &ndash; call `goTo` method before.
- There must be at least one slide.
- This technique is used to [serve responsive images](responsive-images.html).

Some method or property is missing? Found a grammatical mistake? Know how this page can be improved? [Please suggest an edit!](https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/api.md)

