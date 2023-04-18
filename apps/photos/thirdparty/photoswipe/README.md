
:exclamation: **Important note** v5 beta is now available for testing, [read announcement here](https://github.com/dimsemenov/PhotoSwipe/issues/1749) and report any issues that you find, code is within `v5-beta` branch.

## PhotoSwipe Repository 

[![Build Status](https://travis-ci.org/dimsemenov/PhotoSwipe.svg)](https://travis-ci.org/dimsemenov/PhotoSwipe) 

JavaScript image gallery for mobile and desktop. 

- [Documentation and getting started guide](http://photoswipe.com/documentation/getting-started.html).
- [Demo and script home page](http://photoswipe.com).
- [NPM](https://www.npmjs.com/package/photoswipe) `npm install photoswipe`.
- Bower `bower install photoswipe`.

## Location of files

- Compiled PhotoSwipe JS and CSS files, SVG and PNG sprites are in the [dist/](https://github.com/dimsemenov/PhotoSwipe/tree/master/dist) folder.
- Source files (.JS and .SCSS) are in the [src/](https://github.com/dimsemenov/PhotoSwipe/tree/master/src) folder.  Note that PhotoSwipe uses Autoprefixer when compiling SASS files.
- Demo website is in the [website/](https://github.com/dimsemenov/PhotoSwipe/tree/master/website) folder.
- Documentation markdown files are in [website/documentation/](https://github.com/dimsemenov/PhotoSwipe/tree/master/website/documentation).

## Plugins / extensions / addons

- [Ruby gem](https://rubygems.org/gems/photoswipe-rails).
- Ember.js addons: [ember-photoswipe](https://github.com/kaermorchen/ember-photoswipe), [ember-cli-photoswipe](https://github.com/poetic/ember-cli-photoswipe).
- [Eager app](https://eager.io/app/DvuKIoU8iTOt).
- [Koken CMS plugin](https://github.com/DanielMuller/koken-plugin-photoswipe).
- [Orchard CMS module](https://gallery.orchardproject.net/List/Modules/Orchard.Module.Cascade.PhotoSwipe).
- [Yellow CMS plugin](https://github.com/datenstrom/yellow-plugins/tree/master/gallery).
- [Kirby CMS plugin](https://github.com/SiteMarina/guggenheim).
- [Drupal CMF module](https://www.drupal.org/project/photoswipe).
- [ProcessWire CMS module](https://github.com/blynx/MarkupProcesswirePhotoswipe).
- [SPIP CMS module](https://plugins.spip.net/photoswipe.html).
- [Fork CMS MediaLibrary widget](https://github.com/forkcms/forkcms).

Coded something useful? <a href='mailto:diiiimaaaa@gmail.com?subject="PhotoSwipe Plugin"'>Email me</a> and I’ll post a link to it here.

## Build 

To compile PhotoSwipe by yourself, make sure that you have [Node.js](http://nodejs.org/), [Grunt.js](https://github.com/cowboy/grunt), [Ruby](http://www.ruby-lang.org/) and [Jekyll](https://github.com/mojombo/jekyll/) installed, then:

1) Clone the repository

	git clone https://github.com/dimsemenov/PhotoSwipe.git

2) Go inside the PhotoSwipe folder that you fetched and install Node dependencies

	cd PhotoSwipe && npm install

3) Run `grunt` to generate the JS and CSS files in the `dist` folder and the site in the `_site/` folder

	grunt

Optionally:

- Run `grunt watch` to automatically rebuild files (JS, CSS, demo website and documentation) when you change files in `src/` or in `website/`.
- Run `grunt nosite` to build just JS and CSS files (output is folder `dist/`).
- Run `grunt pswpbuild` to build just JS files. Param `--pswp-exclude` allows to exclude modules, for example `grunt pswpbuild --pswp-exclude=history` will exclude history module.

## Using PhotoSwipe?

If you’ve used PhotoSwipe in some interesting way, or on the site of a popular brand, I’d be very grateful if you <a href='mailto:diiiimaaaa@gmail.com?subject="Site that uses PhotoSwipe"'>shoot me</a> a link to it.

## License

Script is licensed under MIT license with one exception: Do not create a public WordPress plugin based on it, as I will develop it. If you need to use it for a public WordPress plugin right now, please ask me by email first. Thanks!

Attribution is not required, but much appreciated, especially if you’re making a product for developers.

## About

PhotoSwipe 4.0+ is developed by [Dmitry Semenov](http://twitter.com/dimsemenov). But initially script was created in 2011 by [Code Computerlove](http://www.codecomputerlove.com/), a digital agency in Manchester, they [passed](https://twitter.com/PhotoSwipe/status/444134042787930113) on development in March 2014. You can view [source and documentation](https://github.com/dimsemenov/PhotoSwipe/tree/v3.0.3) of old PhotoSwipe (<4.0) in history of this repo.


