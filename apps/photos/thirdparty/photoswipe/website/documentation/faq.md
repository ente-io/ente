---

layout: default

title: PhotoSwipe FAQ

h1_title: FAQ

description: Frequently asked questions and known issues about PhotoSwipe image gallery.

addjs: true

canonical_url: http://photoswipe.com/documentation/faq.html

buildtool: true

markdownpage: true

---

## Implementation

### <a name="image-size"></a> I'm unable to predefine image size, what to do?

Use another gallery script ([1](http://dimsemenov.com/plugins/magnific-popup/), [2](http://dimsemenov.com/plugins/royal-slider/gallery/)), or find a way:

- You can read size of an image by downloading only small part of it ([PHP version](http://stackoverflow.com/questions/4635936/super-fast-getimagesize-in-php), [Ruby](https://github.com/sdsykes/fastimage), [Node.js](http://stackoverflow.com/a/20111234/331460)).
- You can store size of an image directly in its filename and parse it on frontend during PhotoSwipe initialization (`gettingData` event in API section). 
- Most CMS store size of an image in a database and have API to retrieve it.
- Most web API (Facebook, 500px, Instagram, Flickr, Twitter, YouTube, Vimeo etc.) return a size of images.

Dimensions are used for progressive loading, stretched placeholder, initial zoom-in transition, panning, zooming, caption positioning. Discussion in GitHub [issue #741](https://github.com/dimsemenov/PhotoSwipe/issues/741).


### <a name="different-thumbnail-dimensions"></a> My thumbnails are square, but large images have different dimensions, what to do with opening/closing transition?

1. If thumbnail aspect ratio does not match large image, do not define `msrc` property for slide objects and enable opacity transition option (`showHideOpacity:true, getThumbBoundsFn:false`).
2. If aspect ratio of thumbnail image file matches large image, **but thumbnail area is cropped via CSS**, just add `showHideOpacity:true` and make sure that `getThumbBoundsFn` option returns coordinates that consider crop area.

I strongly recommend to display thumbnails that match aspect ratio of large image, or crop the visible area via CSS (2).

I'll try to explain why this is not implemented yet. There are two ways to make expanding area animation:

1. Animate `clip` property. But [it forces Paint](http://csstriggers.com/#clip) each time, which makes animations jerky.
2. Wrap an image that expands with two divs that have `overflow:hidden` and reposition them via `transform:translate` during the animation so they clip it at right parts. This method does not force Paint or Layout, but requires two additional elements in markup of each slide. Test prototype showed that it works smooth only on high-end mobile devices (like Nexus 5 with Chrome). Maybe some day I'll implement it.


### <a name="scroll-in-caption"></a> My captions are large, can I add scroll to them?

Refer to [issue #657](https://github.com/dimsemenov/PhotoSwipe/issues/657).


### <a name="inline-gallery"></a>How to implement inline gallery display

Note that this is an experimental feature, for now it doesn't allow to scroll the page vertically over the gallery on mobile (as it calls `prevetDefault()` on touch events). Please report issues if you'll find any. To implement an embedded gallery that flows with the rest of your document, follow these steps:

1. Put the `.pswp` template inside a positioned parent element.
2. Set `modal: false, closeOnScroll: false` options.
3. Modify the `getThumbBoundsFn` (if you're using it) to subtract the template parent's bounding rect.
4. Construct the PhotoSwipe.
5. Listen for the `updateScrollOffset` event and add the template's bounding rect to the offset.
6. `init()` the PhotoSwipe.

[**Live example on CodePen &rarr;**](http://codepen.io/dimsemenov/pen/JogxWM)

```html
<div style="position: relative;" class="parent">
    <div id="gallery" class="pswp"> ... </div>
</div>
```

```javascript
var items = [...];
var template = document.getElementById("gallery"); // .pswp
var options = {
    ...,
    modal: false,
    closeOnScroll: false,
    getThumbBoundsFn: function(index) {
        // rect was the original bounds
        var rect = {x: ..., y: ..., w: ...},

        var templateBounds = template.parentElement.getBoundingClientRect();
        rect.x -= templateBounds.left;
        rect.y -= templateBounds.top;

        return rect;
    }
};
var photoSwipe = new PhotoSwipe(template, PhotoSwipeUI_Default, items, options);
photoSwipe.listen('updateScrollOffset', function(_offset) {
    var r = template.getBoundingClientRect();
    _offset.x += r.left;
    _offset.y += r.top;
});
photoSwipe.init();
```

### <a name="custom-pid-in-url"></a>How to use custom identifiers instead of indexes in URL 

to make URLs to a single image look like this:

```
http://example.com/#&gid=1&pid=custom-first-id
http://example.com/#&gid=1&pid=custom-second-id
```

instead of:

```
http://example.com/#&gid=1&pid=1
http://example.com/#&gid=1&pid=2
```

... enable options `history:true, galleryPIDs:true` and add `pid` (unique picture identifier) property to slide objects (`pid` can be an integer or a string), for example:

```js
var slides = [
    {
        src: 'path/to/1.jpg',
        w:500,
        h:400,
        pid: 'custom-first-id'
    },
    {
        src: 'path/to/2.jpg',
        w:300,
        h:700,
        pid: 'custom-second-id'
    },
    ... 
];
```

- Note that PhotoSwipe does not execute any code until you initialize and open it. That's why on initial page load you need to parse the URL by yourself. Default code from the [Getting Started](http://photoswipe.com/documentation/getting-started.html#dom-to-slide-objects) section of documentation includes this functionality (check `photoswipeParseHash` function if you need some modification).
- Option `galleryPIDs` is available since PhotoSwipe v4.0.8 ([option description](options.html#galleryPIDs)).


## Bugs

### <a name="gif-freeze-ios"></a> GIF images sometimes freeze on iOS8

iOS Safari has a bug that freezes GIF images that are shifted outside of the window (or outside of element with `overflow:hidden`). My recommendation is to avoid using animated GIFs in PhotoSwipe at all, as they slow down animation performance in any mobile browser. But if you really need to use it, refer to [this hack](https://github.com/dimsemenov/PhotoSwipe/issues/662#issuecomment-66420874).


### <a name="mobile-crash"></a> Mobile browser crashes when opening gallery with huge images

Mostly, it can happen on mobile devices with low memory limit &ndash; iOS Safari, default browser in old Android (before KitKat). The most common reason of a crash is too big images (usually larger than 2000x1500px). PhotoSwipe applies hardware-acceleration on images, which consumes more memory than regular image on page, so when you run out of limit browser starts lagging or even crashes.

So [serve responsive images](responsive-images.html), or at least don't serve huge images. Ideally, for an average 900x600 phone you should serve 1200px wide image. Note that if everything works smoothly in iOS Simulator, it doesn't mean that crash won't occur on real device. 

In much more rare cases crash can occur if you open PhotoSwipe during some process on your page (this can be initial page load/render, or some complex animation on page), try to delay PhotoSwipe initialization until page is rendered (18-300ms after document.ready), especially if you are displaying large images.

**UPD.:** in [v4.1.0](https://github.com/dimsemenov/PhotoSwipe/releases/tag/v4.1.0) this is partly fixed. 

## Miscellaneous

### <a name="keep-updated"></a> Where is the changelog, how to do I get notified about updates?

Each time PhotoSwipe gets an update - [GitHub releases](https://github.com/dimsemenov/PhotoSwipe/releases) page is updated with details. 
Releases page has an [Atom feed](https://github.com/dimsemenov/PhotoSwipe/releases.atom), you may setup email notifications when feed is updated [using IFTTT](https://ifttt.com/recipes/230902-photoswipe-update-notification).

Also, you may join my [email newsletter](http://dimsemenov.com/subscribe.html?i=pswp) (sent 3-4 times a year), follow [@PhotoSwipe on Twitter](http://twitter.com/photoswipe), and star/watch [PhotoSwipe on GitHub](https://github.com/dimsemenov/PhotoSwipe/).

### <a name="wordpress-release"></a> When WordPress plugin will be released?

Plugin is under development and will be released in 2015. To get notified [subscribe to my newsletter](http://dimsemenov.com/subscribe.html?i=pswp-wp).


### <a name="can-i-use-in-theme"></a> I want to use PhotoSwipe in WordPress/Magento/Joomla... template, can I?

Yes, you can use PhotoSwipe in a free or commercial themes without any limitations. If you can, please leave a credit (link to PhotoSwipe homepage) in theme description or/and in admin area.


<div style="margin-top:30px;"><p>Know how this page can be improved? Found a grammatical mistake? <a href="https://github.com/dimsemenov/PhotoSwipe/blob/master/website/documentation/responsive-images.md">Please suggest an edit!</a></p></div>

<iframe src="http://ghbtns.com/github-btn.html?user=dimsemenov&amp;repo=photoswipe&amp;type=watch&amp;count=true&amp;size=large" allowtransparency="true" frameborder="0" scrolling="0" width="155" height="30" style=""></iframe>

<style type="text/css">
body {
    overflow-y:scroll;
}
h3 {
    cursor: pointer;
    font-weight: normal;
    -webkit-user-select:none;
    -moz-user-select:none;
    user-select:none;
    color: #3169B3;
    padding-left: 18px;
    position: relative;
}
h3:hover {
    color: #C00;
}
h3:before {
    content:'▼';
    font-size: 12px;
    position: absolute;
    left: 0;
    top: 2px;
}
h3.tab-closed:before {
    content: '►';
}
</style>

<script>
(function() {

    // tabs

    if(!document.addEventListener) {
        return;
    }

    var els = document.getElementsByClassName('row--docs')[0].children,
        el;

    var isContentEl = function(el) {
            if(!el) {
                return;
            }
            if( (/(P|UL|OL)/i).test(el.tagName) || el.className === 'highlight' ) {
                return true;
            }
            return;
        },
        toggleTab = function(el) {
            var dStyle = el.classList.contains('tab-closed') ? 'block' : 'none';
            el.classList.toggle('tab-closed');

            var s = el.nextElementSibling;
            while( isContentEl(s) ) {
                s.style.display = dStyle;
                s = s.nextElementSibling;
            }
        };

    for(var i = 0; i < els.length; i++) {
        el = els[i];

        if(el.tagName === 'H3') {

            if(window.location.hash !== '#' + el.firstElementChild.name) {
                toggleTab(el);
            }
            
            el.onclick = function() {
                toggleTab(this);
            };
        }
    }

})();
</script>

