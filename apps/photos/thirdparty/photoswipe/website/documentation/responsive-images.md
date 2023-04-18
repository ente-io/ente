---

layout: default

title: Serving responsive images in PhotoSwipe

h1_title: Responsive Images

description: The complete guide on how to serve responsive images in PhotoSwipe.

addjs: true

canonical_url: http://photoswipe.com/documentation/responsive-images.html

buildtool: true

markdownpage: true

---

PhotoSwipe does not support `<picture>` or `srcset`, as it requires defined image dimensions and uses lazy-loading. But as images are loaded dynamically, it's quite easy to switch sources, even in old browsers that don't support `srcset`.

Let's assume that you have just "medium" images and "original" ("large") images. First of all, you need to store path and size of the image in slide object, for example like so:

```javascript
var items = [

	// Slide 1
	{
		mediumImage: {
			src: 'path/to/medium-image-1.jpg',
			w:800,
			h:600
		},
		originalImage: {
			src: 'path/to/large-image-1.jpg',
			w: 1400,
			h: 1050
		}
	},

	// Slide 2
	// {
	//     mediumImage: {
	//         src: 'path/to/medium-image-2.jpg',
	//         ...
	//     
	// ...
		
];
```

Then:


```javascript
// initialise as usual
var gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);

// create variable that will store real size of viewport
var realViewportWidth,
	useLargeImages = false,
	firstResize = true,
	imageSrcWillChange;

// beforeResize event fires each time size of gallery viewport updates
gallery.listen('beforeResize', function() {
	// gallery.viewportSize.x - width of PhotoSwipe viewport
	// gallery.viewportSize.y - height of PhotoSwipe viewport
	// window.devicePixelRatio - ratio between physical pixels and device independent pixels (Number)
	//							1 (regular display), 2 (@2x, retina) ...
	

	// calculate real pixels when size changes
	realViewportWidth = gallery.viewportSize.x * window.devicePixelRatio;
	
	// Code below is needed if you want image to switch dynamically on window.resize
	
	// Find out if current images need to be changed
	if(useLargeImages && realViewportWidth < 1000) {
		useLargeImages = false;
		imageSrcWillChange = true;
	} else if(!useLargeImages && realViewportWidth >= 1000) {
		useLargeImages = true;
		imageSrcWillChange = true;
	}

	// Invalidate items only when source is changed and when it's not the first update
	if(imageSrcWillChange && !firstResize) {
		// invalidateCurrItems sets a flag on slides that are in DOM,
		// which will force update of content (image) on window.resize.
		gallery.invalidateCurrItems();
	}

	if(firstResize) {
		firstResize = false;
	}

	imageSrcWillChange = false;

});


// gettingData event fires each time PhotoSwipe retrieves image source & size
gallery.listen('gettingData', function(index, item) {

	// Set image source & size based on real viewport width
	if( useLargeImages ) {
		item.src = item.originalImage.src;
		item.w = item.originalImage.w;
		item.h = item.originalImage.h;
	} else {
		item.src = item.mediumImage.src;
		item.w = item.mediumImage.w;
		item.h = item.mediumImage.h;
	}

	// It doesn't really matter what will you do here, 
	// as long as item.src, item.w and item.h have valid values.
	// 
	// Just avoid http requests in this listener, as it fires quite often

});


// Note that init() method is called after gettingData event is bound
gallery.init();

```

- You are not obliged to use structure of slide object that looks exactly like above (with `mediumImage` and `largeImage` objects). For example, you may store size of image directly in image filename (`/path/to/large-image-600x500.jpg`) and then parse size in `gettingData` event. Only `item.src`, `item.w`, and `item.h` properties are read by PhotoSwipe and only after `gettingData` event is fired.
- The larger the image, the less smooth animations will look.
- Try to avoid serving images just based on devicePixelRatio or just based on viewport size, always combine both.
- Feel free to use `srcset` on thumbnails that open PhotoSwipe.




Know how this guide can be improved? [Suggest an edit!](https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/responsive-images.md)

