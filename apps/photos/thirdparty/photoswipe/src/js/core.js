//function(template, UiClass, items, options)

var self = this;

/**
 * Static vars, don't change unless you know what you're doing.
 */
var DOUBLE_TAP_RADIUS = 25,
    NUM_HOLDERS = 3;

/**
 * Options
 */
var _options = {
    allowPanToNext: true,
    spacing: 0.12,
    bgOpacity: 1,
    mouseUsed: false,
    loop: true,
    pinchToClose: true,
    closeOnScroll: true,
    closeOnVerticalDrag: true,
    verticalDragRange: 0.75,
    hideAnimationDuration: 333,
    showAnimationDuration: 333,
    showHideOpacity: false,
    focus: true,
    escKey: true,
    arrowKeys: true,
    mainScrollEndFriction: 0.35,
    panEndFriction: 0.35,
    isClickableElement: function (el) {
        return el.tagName === 'A';
    },
    getDoubleTapZoom: function (isMouseClick, item) {
        if (isMouseClick) {
            return 1;
        } else {
            return item.initialZoomLevel < 0.7 ? 1 : 1.33;
        }
    },
    maxSpreadZoom: 1.33,
    modal: true,

    // not fully implemented yet
    scaleMode: 'fit', // TODO
};
framework.extend(_options, options);

/**
 * Private helper variables & functions
 */

var _getEmptyPoint = function () {
    return { x: 0, y: 0 };
};

var _isOpen,
    _isDestroying,
    _closedByScroll,
    _currentItemIndex,
    _containerStyle,
    _containerShiftIndex,
    _currPanDist = _getEmptyPoint(),
    _startPanOffset = _getEmptyPoint(),
    _panOffset = _getEmptyPoint(),
    _upMoveEvents, // drag move, drag end & drag cancel events array
    _downEvents, // drag start events array
    _globalEventHandlers,
    _viewportSize = {},
    _currZoomLevel,
    _startZoomLevel,
    _translatePrefix,
    _translateSufix,
    _updateSizeInterval,
    _itemsNeedUpdate,
    _currPositionIndex = 0,
    _offset = {},
    _slideSize = _getEmptyPoint(), // size of slide area, including spacing
    _itemHolders,
    _prevItemIndex,
    _indexDiff = 0, // difference of indexes since last content update
    _dragStartEvent,
    _dragMoveEvent,
    _dragEndEvent,
    _dragCancelEvent,
    _transformKey,
    _pointerEventEnabled,
    _isFixedPosition = true,
    _likelyTouchDevice,
    _modules = [],
    _requestAF,
    _cancelAF,
    _initalClassName,
    _initalWindowScrollY,
    _oldIE,
    _currentWindowScrollY,
    _features,
    _windowVisibleSize = {},
    _renderMaxResolution = false,
    _orientationChangeTimeout,
    // Registers PhotoSWipe module (History, Controller ...)
    _registerModule = function (name, module) {
        framework.extend(self, module.publicMethods);
        _modules.push(name);
    },
    _getLoopedId = function (index) {
        var numSlides = _getNumItems();
        if (index > numSlides - 1) {
            return index - numSlides;
        } else if (index < 0) {
            return numSlides + index;
        }
        return index;
    },
    // Micro bind/trigger
    _listeners = {},
    _listen = function (name, fn) {
        if (!_listeners[name]) {
            _listeners[name] = [];
        }
        return _listeners[name].push(fn);
    },
    _shout = function (name) {
        var listeners = _listeners[name];

        if (listeners) {
            var args = Array.prototype.slice.call(arguments);
            args.shift();

            for (var i = 0; i < listeners.length; i++) {
                listeners[i].apply(self, args);
            }
        }
    },
    _getCurrentTime = function () {
        return new Date().getTime();
    },
    _applyBgOpacity = function (opacity) {
        _bgOpacity = opacity;
        self.bg.style.opacity = opacity * _options.bgOpacity;
    },
    _applyZoomTransform = function (styleObj, x, y, zoom, item) {
        if (!_renderMaxResolution || (item && item !== self.currItem)) {
            zoom = zoom / (item ? item.fitRatio : self.currItem.fitRatio);
        }

        styleObj[_transformKey] =
            _translatePrefix +
            x +
            'px, ' +
            y +
            'px' +
            _translateSufix +
            ' scale(' +
            zoom +
            ')';
    },
    _applyCurrentZoomPan = function (allowRenderResolution) {
        if (_currZoomElementStyle) {
            if (allowRenderResolution) {
                if (_currZoomLevel > self.currItem.fitRatio) {
                    if (!_renderMaxResolution) {
                        _setImageSize(self.currItem, false, true);
                        _renderMaxResolution = true;
                    }
                } else {
                    if (_renderMaxResolution) {
                        _setImageSize(self.currItem);
                        _renderMaxResolution = false;
                    }
                }
            }

            _applyZoomTransform(
                _currZoomElementStyle,
                _panOffset.x,
                _panOffset.y,
                _currZoomLevel
            );
        }
    },
    _applyZoomPanToItem = function (item) {
        if (item.container) {
            if (!item.initialPosition) {
                item.initialPosition = { x: 0, y: 0 };
            }
            _applyZoomTransform(
                item.container.style,
                item.initialPosition.x,
                item.initialPosition.y,
                item.initialZoomLevel,
                item
            );
        }
    },
    _setTranslateX = function (x, elStyle) {
        elStyle[_transformKey] =
            _translatePrefix + x + 'px, 0px' + _translateSufix;
    },
    _moveMainScroll = function (x, dragging) {
        if (!_options.loop && dragging) {
            var newSlideIndexOffset =
                    _currentItemIndex +
                    (_slideSize.x * _currPositionIndex - x) / _slideSize.x,
                delta = Math.round(x - _mainScrollPos.x);

            if (
                (newSlideIndexOffset < 0 && delta > 0) ||
                (newSlideIndexOffset >= _getNumItems() - 1 && delta < 0)
            ) {
                x = _mainScrollPos.x + delta * _options.mainScrollEndFriction;
            }
        }

        _mainScrollPos.x = x;
        _setTranslateX(x, _containerStyle);
    },
    _calculatePanOffset = function (axis, zoomLevel) {
        var m = _midZoomPoint[axis] - _offset[axis];
        return (
            _startPanOffset[axis] +
            _currPanDist[axis] +
            m -
            m * (zoomLevel / _startZoomLevel)
        );
    },
    _equalizePoints = function (p1, p2) {
        p1.x = p2.x;
        p1.y = p2.y;
        if (p2.id) {
            p1.id = p2.id;
        }
    },
    _roundPoint = function (p) {
        p.x = Math.round(p.x);
        p.y = Math.round(p.y);
    },
    _mouseMoveTimeout = null,
    _onFirstMouseMove = function () {
        // Wait until mouse move event is fired at least twice during 100ms
        // We do this, because some mobile browsers trigger it on touchstart
        if (_mouseMoveTimeout) {
            framework.unbind(document, 'mousemove', _onFirstMouseMove);
            framework.addClass(template, 'pswp--has_mouse');
            _options.mouseUsed = true;
            _shout('mouseUsed');
        }
        _mouseMoveTimeout = setTimeout(function () {
            _mouseMoveTimeout = null;
        }, 100);
    },
    _bindEvents = function () {
        framework.bind(document, 'keydown', self);

        if (_features.transform) {
            // don't bind click event in browsers that don't support transform (mostly IE8)
            framework.bind(self.scrollWrap, 'click', self);
        }

        if (!_options.mouseUsed) {
            framework.bind(document, 'mousemove', _onFirstMouseMove);
        }

        framework.bind(window, 'resize scroll orientationchange', self);

        _shout('bindEvents');
    },
    _unbindEvents = function () {
        framework.unbind(window, 'resize scroll orientationchange', self);
        framework.unbind(window, 'scroll', _globalEventHandlers.scroll);
        framework.unbind(document, 'keydown', self);
        framework.unbind(document, 'mousemove', _onFirstMouseMove);

        if (_features.transform) {
            framework.unbind(self.scrollWrap, 'click', self);
        }

        if (_isDragging) {
            framework.unbind(window, _upMoveEvents, self);
        }

        clearTimeout(_orientationChangeTimeout);

        _shout('unbindEvents');
    },
    _calculatePanBounds = function (zoomLevel, update) {
        var bounds = _calculateItemSize(
            self.currItem,
            _viewportSize,
            zoomLevel
        );
        if (update) {
            _currPanBounds = bounds;
        }
        return bounds;
    },
    _getMinZoomLevel = function (item) {
        if (!item) {
            item = self.currItem;
        }
        return item.initialZoomLevel;
    },
    _getMaxZoomLevel = function (item) {
        if (!item) {
            item = self.currItem;
        }
        return item.w > 0 ? _options.maxSpreadZoom : 1;
    },
    // Return true if offset is out of the bounds
    _modifyDestPanOffset = function (
        axis,
        destPanBounds,
        destPanOffset,
        destZoomLevel
    ) {
        if (destZoomLevel === self.currItem.initialZoomLevel) {
            destPanOffset[axis] = self.currItem.initialPosition[axis];
            return true;
        } else {
            destPanOffset[axis] = _calculatePanOffset(axis, destZoomLevel);

            if (destPanOffset[axis] > destPanBounds.min[axis]) {
                destPanOffset[axis] = destPanBounds.min[axis];
                return true;
            } else if (destPanOffset[axis] < destPanBounds.max[axis]) {
                destPanOffset[axis] = destPanBounds.max[axis];
                return true;
            }
        }
        return false;
    },
    _setupTransforms = function () {
        if (_transformKey) {
            // setup 3d transforms
            var allow3dTransform = _features.perspective && !_likelyTouchDevice;
            _translatePrefix = 'translate' + (allow3dTransform ? '3d(' : '(');
            _translateSufix = _features.perspective ? ', 0px)' : ')';
            return;
        }

        // Override zoom/pan/move functions in case old browser is used (most likely IE)
        // (so they use left/top/width/height, instead of CSS transform)

        _transformKey = 'left';
        framework.addClass(template, 'pswp--ie');

        _setTranslateX = function (x, elStyle) {
            elStyle.left = x + 'px';
        };
        _applyZoomPanToItem = function (item) {
            var zoomRatio = item.fitRatio > 1 ? 1 : item.fitRatio,
                s = item.container.style,
                w = zoomRatio * item.w,
                h = zoomRatio * item.h;

            s.width = w + 'px';
            s.height = h + 'px';
            s.left = item.initialPosition.x + 'px';
            s.top = item.initialPosition.y + 'px';
        };
        _applyCurrentZoomPan = function () {
            if (_currZoomElementStyle) {
                var s = _currZoomElementStyle,
                    item = self.currItem,
                    zoomRatio = item.fitRatio > 1 ? 1 : item.fitRatio,
                    w = zoomRatio * item.w,
                    h = zoomRatio * item.h;

                s.width = w + 'px';
                s.height = h + 'px';

                s.left = _panOffset.x + 'px';
                s.top = _panOffset.y + 'px';
            }
        };
    },
    _onKeyDown = function (e) {
        var keydownAction = '';
        if (_options.escKey && e.keyCode === 27) {
            keydownAction = 'close';
        } else if (_options.arrowKeys) {
            if (e.keyCode === 37) {
                keydownAction = 'prev';
            } else if (e.keyCode === 39) {
                keydownAction = 'next';
            }
        }

        if (keydownAction) {
            // don't do anything if special key pressed to prevent from overriding default browser actions
            // e.g. in Chrome on Mac cmd+arrow-left returns to previous page
            if (!e.ctrlKey && !e.altKey && !e.shiftKey && !e.metaKey) {
                if (e.preventDefault) {
                    e.preventDefault();
                } else {
                    e.returnValue = false;
                }
                self[keydownAction]();
            }
        }
    },
    _onGlobalClick = function (e) {
        if (!e) {
            return;
        }

        // don't allow click event to pass through when triggering after drag or some other gesture
        if (
            _moved ||
            _zoomStarted ||
            _mainScrollAnimating ||
            _verticalDragInitiated
        ) {
            e.preventDefault();
            e.stopPropagation();
        }
    },
    _updatePageScrollOffset = function () {
        self.setScrollOffset(0, framework.getScrollY());
    };

// Micro animation engine
var _animations = {},
    _numAnimations = 0,
    _stopAnimation = function (name) {
        if (_animations[name]) {
            if (_animations[name].raf) {
                _cancelAF(_animations[name].raf);
            }
            _numAnimations--;
            delete _animations[name];
        }
    },
    _registerStartAnimation = function (name) {
        if (_animations[name]) {
            _stopAnimation(name);
        }
        if (!_animations[name]) {
            _numAnimations++;
            _animations[name] = {};
        }
    },
    _stopAllAnimations = function () {
        for (var prop in _animations) {
            if (_animations.hasOwnProperty(prop)) {
                _stopAnimation(prop);
            }
        }
    },
    _animateProp = function (
        name,
        b,
        endProp,
        d,
        easingFn,
        onUpdate,
        onComplete
    ) {
        var startAnimTime = _getCurrentTime(),
            t;
        _registerStartAnimation(name);

        var animloop = function () {
            if (_animations[name]) {
                t = _getCurrentTime() - startAnimTime; // time diff
                //b - beginning (start prop)
                //d - anim duration

                if (t >= d) {
                    _stopAnimation(name);
                    onUpdate(endProp);
                    if (onComplete) {
                        onComplete();
                    }
                    return;
                }
                onUpdate((endProp - b) * easingFn(t / d) + b);

                _animations[name].raf = _requestAF(animloop);
            }
        };
        animloop();
    };

var publicMethods = {
    // make a few local variables and functions public
    shout: _shout,
    listen: _listen,
    viewportSize: _viewportSize,
    options: _options,

    isMainScrollAnimating: function () {
        return _mainScrollAnimating;
    },
    getZoomLevel: function () {
        return _currZoomLevel;
    },
    getCurrentIndex: function () {
        return _currentItemIndex;
    },
    isDragging: function () {
        return _isDragging;
    },
    isZooming: function () {
        return _isZooming;
    },
    setScrollOffset: function (x, y) {
        _offset.x = x;
        _currentWindowScrollY = _offset.y = y;
        _shout('updateScrollOffset', _offset);
    },
    applyZoomPan: function (zoomLevel, panX, panY, allowRenderResolution) {
        _panOffset.x = panX;
        _panOffset.y = panY;
        _currZoomLevel = zoomLevel;
        _applyCurrentZoomPan(allowRenderResolution);
    },

    init: function () {
        if (_isOpen || _isDestroying) {
            return;
        }

        var i;

        self.framework = framework; // basic functionality
        self.template = template; // root DOM element of PhotoSwipe
        self.bg = framework.getChildByClass(template, 'pswp__bg');

        _initalClassName = template.className;
        _isOpen = true;

        _features = framework.detectFeatures();
        _requestAF = _features.raf;
        _cancelAF = _features.caf;
        _transformKey = _features.transform;
        _oldIE = _features.oldIE;

        self.scrollWrap = framework.getChildByClass(
            template,
            'pswp__scroll-wrap'
        );
        self.container = framework.getChildByClass(
            self.scrollWrap,
            'pswp__container'
        );

        _containerStyle = self.container.style; // for fast access

        // Objects that hold slides (there are only 3 in DOM)
        self.itemHolders = _itemHolders = [
            { el: self.container.children[0], wrap: 0, index: -1 },
            { el: self.container.children[1], wrap: 0, index: -1 },
            { el: self.container.children[2], wrap: 0, index: -1 },
        ];

        // hide nearby item holders until initial zoom animation finishes (to avoid extra Paints)
        _itemHolders[0].el.style.display = _itemHolders[2].el.style.display =
            'none';

        _setupTransforms();

        // Setup global events
        _globalEventHandlers = {
            resize: self.updateSize,

            // Fixes: iOS 10.3 resize event
            // does not update scrollWrap.clientWidth instantly after resize
            // https://github.com/dimsemenov/PhotoSwipe/issues/1315
            orientationchange: function () {
                clearTimeout(_orientationChangeTimeout);
                _orientationChangeTimeout = setTimeout(function () {
                    if (_viewportSize.x !== self.scrollWrap.clientWidth) {
                        self.updateSize();
                    }
                }, 500);
            },
            scroll: _updatePageScrollOffset,
            keydown: _onKeyDown,
            click: _onGlobalClick,
        };

        // disable show/hide effects on old browsers that don't support CSS animations or transforms,
        // old IOS, Android and Opera mobile. Blackberry seems to work fine, even older models.
        var oldPhone =
            _features.isOldIOSPhone ||
            _features.isOldAndroid ||
            _features.isMobileOpera;
        if (!_features.animationName || !_features.transform || oldPhone) {
            _options.showAnimationDuration = _options.hideAnimationDuration = 0;
        }

        // init modules
        for (i = 0; i < _modules.length; i++) {
            self['init' + _modules[i]]();
        }

        // init
        if (UiClass) {
            var ui = (self.ui = new UiClass(self, framework));
            ui.init();
        }

        _shout('firstUpdate');
        _currentItemIndex = _currentItemIndex || _options.index || 0;
        // validate index
        if (
            isNaN(_currentItemIndex) ||
            _currentItemIndex < 0 ||
            _currentItemIndex >= _getNumItems()
        ) {
            _currentItemIndex = 0;
        }
        self.currItem = _getItemAt(_currentItemIndex);

        if (_features.isOldIOSPhone || _features.isOldAndroid) {
            _isFixedPosition = false;
        }

        template.setAttribute('aria-hidden', 'false');
        if (_options.modal) {
            if (!_isFixedPosition) {
                template.style.position = 'absolute';
                template.style.top = framework.getScrollY() + 'px';
            } else {
                template.style.position = 'fixed';
            }
        }

        if (_currentWindowScrollY === undefined) {
            _shout('initialLayout');
            _currentWindowScrollY = _initalWindowScrollY =
                framework.getScrollY();
        }

        // add classes to root element of PhotoSwipe
        var rootClasses = 'pswp--open ';
        if (_options.mainClass) {
            rootClasses += _options.mainClass + ' ';
        }
        if (_options.showHideOpacity) {
            rootClasses += 'pswp--animate_opacity ';
        }
        rootClasses += _likelyTouchDevice ? 'pswp--touch' : 'pswp--notouch';
        rootClasses += _features.animationName ? ' pswp--css_animation' : '';
        rootClasses += _features.svg ? ' pswp--svg' : '';
        framework.addClass(template, rootClasses);

        self.updateSize();

        // initial update
        _containerShiftIndex = -1;
        _indexDiff = null;
        for (i = 0; i < NUM_HOLDERS; i++) {
            _setTranslateX(
                (i + _containerShiftIndex) * _slideSize.x,
                _itemHolders[i].el.style
            );
        }

        if (!_oldIE) {
            framework.bind(self.scrollWrap, _downEvents, self); // no dragging for old IE
        }

        _listen('initialZoomInEnd', function () {
            self.setContent(_itemHolders[0], _currentItemIndex - 1);
            self.setContent(_itemHolders[2], _currentItemIndex + 1);

            _itemHolders[0].el.style.display =
                _itemHolders[2].el.style.display = 'block';

            if (_options.focus) {
                // focus causes layout,
                // which causes lag during the animation,
                // that's why we delay it untill the initial zoom transition ends
                template.focus();
            }

            _bindEvents();
        });

        // set content for center slide (first time)
        self.setContent(_itemHolders[1], _currentItemIndex);

        self.updateCurrItem();

        _shout('afterInit');

        if (!_isFixedPosition) {
            // On all versions of iOS lower than 8.0, we check size of viewport every second.
            //
            // This is done to detect when Safari top & bottom bars appear,
            // as this action doesn't trigger any events (like resize).
            //
            // On iOS8 they fixed this.
            //
            // 10 Nov 2014: iOS 7 usage ~40%. iOS 8 usage 56%.

            _updateSizeInterval = setInterval(function () {
                if (
                    !_numAnimations &&
                    !_isDragging &&
                    !_isZooming &&
                    _currZoomLevel === self.currItem.initialZoomLevel
                ) {
                    self.updateSize();
                }
            }, 1000);
        }

        framework.addClass(template, 'pswp--visible');
    },

    isOpen: function () {
        return _isOpen;
    },

    // Close the gallery, then destroy it
    close: function () {
        if (!_isOpen) {
            return;
        }

        _isOpen = false;
        _isDestroying = true;
        _shout('close');
        _unbindEvents();

        _showOrHide(self.currItem, null, true, self.destroy);
    },

    // destroys the gallery (unbinds events, cleans up intervals and timeouts to avoid memory leaks)
    destroy: function () {
        _shout('destroy');

        if (_showOrHideTimeout) {
            clearTimeout(_showOrHideTimeout);
        }

        template.setAttribute('aria-hidden', 'true');
        template.className = _initalClassName;

        if (_updateSizeInterval) {
            clearInterval(_updateSizeInterval);
        }

        framework.unbind(self.scrollWrap, _downEvents, self);

        // we unbind scroll event at the end, as closing animation may depend on it
        framework.unbind(window, 'scroll', self);

        _stopDragUpdateLoop();

        _stopAllAnimations();

        _listeners = null;
    },

    /**
     * Pan image to position
     * @param {Number} x
     * @param {Number} y
     * @param {Boolean} force Will ignore bounds if set to true.
     */
    panTo: function (x, y, force) {
        if (!force && _currPanBounds) {
            if (x > _currPanBounds.min.x) {
                x = _currPanBounds.min.x;
            } else if (x < _currPanBounds.max.x) {
                x = _currPanBounds.max.x;
            }

            if (y > _currPanBounds.min.y) {
                y = _currPanBounds.min.y;
            } else if (y < _currPanBounds.max.y) {
                y = _currPanBounds.max.y;
            }
        }

        _panOffset.x = x;
        _panOffset.y = y;
        _applyCurrentZoomPan();
    },

    handleEvent: function (e) {
        e = e || window.event;
        if (_globalEventHandlers[e.type]) {
            _globalEventHandlers[e.type](e);
        }
    },

    goTo: function (index) {
        index = _getLoopedId(index);

        var diff = index - _currentItemIndex;
        _indexDiff = diff;

        _currentItemIndex = index;
        self.currItem = _getItemAt(_currentItemIndex);
        _currPositionIndex -= diff;

        _moveMainScroll(_slideSize.x * _currPositionIndex);

        _stopAllAnimations();
        _mainScrollAnimating = false;

        self.updateCurrItem();
    },
    next: function () {
        self.goTo(_currentItemIndex + 1);
    },
    prev: function () {
        self.goTo(_currentItemIndex - 1);
    },

    // update current zoom/pan objects
    updateCurrZoomItem: function (emulateSetContent) {
        if (emulateSetContent) {
            _shout('beforeChange', 0);
        }

        // itemHolder[1] is middle (current) item
        if (_itemHolders[1].el.children.length) {
            var zoomElement = _itemHolders[1].el.children[0];
            if (framework.hasClass(zoomElement, 'pswp__zoom-wrap')) {
                _currZoomElementStyle = zoomElement.style;
            } else {
                _currZoomElementStyle = null;
            }
        } else {
            _currZoomElementStyle = null;
        }

        _currPanBounds = self.currItem.bounds;
        _startZoomLevel = _currZoomLevel = self.currItem.initialZoomLevel;
        if (_currPanBounds) {
            _panOffset.x = _currPanBounds.center.x;
            _panOffset.y = _currPanBounds.center.y;
        }
        if (emulateSetContent) {
            _shout('afterChange');
        }
    },

    invalidateCurrItems: function () {
        _itemsNeedUpdate = true;
        for (var i = 0; i < NUM_HOLDERS; i++) {
            if (_itemHolders[i].item) {
                _itemHolders[i].item.needsUpdate = true;
            }
        }
    },

    updateCurrItem: function (beforeAnimation) {
        if (_indexDiff === 0) {
            return;
        }

        var diffAbs = Math.abs(_indexDiff),
            tempHolder;

        if (beforeAnimation && diffAbs < 2) {
            return;
        }

        self.currItem = _getItemAt(_currentItemIndex);
        _renderMaxResolution = false;

        _shout('beforeChange', _indexDiff);

        if (diffAbs >= NUM_HOLDERS) {
            _containerShiftIndex +=
                _indexDiff + (_indexDiff > 0 ? -NUM_HOLDERS : NUM_HOLDERS);
            diffAbs = NUM_HOLDERS;
        }
        for (var i = 0; i < diffAbs; i++) {
            if (_indexDiff > 0) {
                tempHolder = _itemHolders.shift();
                _itemHolders[NUM_HOLDERS - 1] = tempHolder; // move first to last

                _containerShiftIndex++;
                _setTranslateX(
                    (_containerShiftIndex + 2) * _slideSize.x,
                    tempHolder.el.style
                );
                self.setContent(
                    tempHolder,
                    _currentItemIndex - diffAbs + i + 1 + 1
                );
            } else {
                tempHolder = _itemHolders.pop();
                _itemHolders.unshift(tempHolder); // move last to first

                _containerShiftIndex--;
                _setTranslateX(
                    _containerShiftIndex * _slideSize.x,
                    tempHolder.el.style
                );
                self.setContent(
                    tempHolder,
                    _currentItemIndex + diffAbs - i - 1 - 1
                );
            }
        }

        // reset zoom/pan on previous item
        if (_currZoomElementStyle && Math.abs(_indexDiff) === 1) {
            var prevItem = _getItemAt(_prevItemIndex);
            if (prevItem.initialZoomLevel !== _currZoomLevel) {
                _calculateItemSize(prevItem, _viewportSize);
                _setImageSize(prevItem);
                _applyZoomPanToItem(prevItem);
            }
        }

        // reset diff after update
        _indexDiff = 0;

        self.updateCurrZoomItem();

        _prevItemIndex = _currentItemIndex;

        _shout('afterChange');
    },

    updateSize: function (force) {
        if (!_isFixedPosition && _options.modal) {
            var windowScrollY = framework.getScrollY();
            if (_currentWindowScrollY !== windowScrollY) {
                template.style.top = windowScrollY + 'px';
                _currentWindowScrollY = windowScrollY;
            }
            if (
                !force &&
                _windowVisibleSize.x === window.innerWidth &&
                _windowVisibleSize.y === window.innerHeight
            ) {
                return;
            }
            _windowVisibleSize.x = window.innerWidth;
            _windowVisibleSize.y = window.innerHeight;

            //template.style.width = _windowVisibleSize.x + 'px';
            template.style.height = _windowVisibleSize.y + 'px';
        }

        _viewportSize.x = self.scrollWrap.clientWidth;
        _viewportSize.y = self.scrollWrap.clientHeight;

        _updatePageScrollOffset();

        _slideSize.x =
            _viewportSize.x + Math.round(_viewportSize.x * _options.spacing);
        _slideSize.y = _viewportSize.y;

        _moveMainScroll(_slideSize.x * _currPositionIndex);

        _shout('beforeResize'); // even may be used for example to switch image sources

        // don't re-calculate size on inital size update
        if (_containerShiftIndex !== undefined) {
            var holder, item, hIndex;

            for (var i = 0; i < NUM_HOLDERS; i++) {
                holder = _itemHolders[i];
                _setTranslateX(
                    (i + _containerShiftIndex) * _slideSize.x,
                    holder.el.style
                );

                hIndex = _currentItemIndex + i - 1;

                if (_options.loop && _getNumItems() > 2) {
                    hIndex = _getLoopedId(hIndex);
                }

                // update zoom level on items and refresh source (if needsUpdate)
                item = _getItemAt(hIndex);

                // re-render gallery item if `needsUpdate`,
                // or doesn't have `bounds` (entirely new slide object)
                if (
                    item &&
                    (_itemsNeedUpdate || item.needsUpdate || !item.bounds)
                ) {
                    self.cleanSlide(item);

                    self.setContent(holder, hIndex);

                    // if "center" slide
                    if (i === 1) {
                        self.currItem = item;
                        self.updateCurrZoomItem(true);
                    }

                    item.needsUpdate = false;
                } else if (holder.index === -1 && hIndex >= 0) {
                    // add content first time
                    self.setContent(holder, hIndex);
                }
                if (item && item.container) {
                    _calculateItemSize(item, _viewportSize);
                    _setImageSize(item);
                    _applyZoomPanToItem(item);
                }
            }
            _itemsNeedUpdate = false;
        }

        _startZoomLevel = _currZoomLevel = self.currItem.initialZoomLevel;
        _currPanBounds = self.currItem.bounds;

        if (_currPanBounds) {
            _panOffset.x = _currPanBounds.center.x;
            _panOffset.y = _currPanBounds.center.y;
            _applyCurrentZoomPan(true);
        }

        _shout('resize');
    },

    // Zoom current item to
    zoomTo: function (destZoomLevel, centerPoint, speed, easingFn, updateFn) {
        /*
			if(destZoomLevel === 'fit') {
				destZoomLevel = self.currItem.fitRatio;
			} else if(destZoomLevel === 'fill') {
				destZoomLevel = self.currItem.fillRatio;
			}
		*/

        if (centerPoint && _panOffset) {
            _startZoomLevel = _currZoomLevel;
            _midZoomPoint.x = Math.abs(centerPoint.x) - _panOffset.x;
            _midZoomPoint.y = Math.abs(centerPoint.y) - _panOffset.y;
            _equalizePoints(_startPanOffset, _panOffset);
        }

        var destPanBounds = _calculatePanBounds(destZoomLevel, false),
            destPanOffset = {};

        _modifyDestPanOffset('x', destPanBounds, destPanOffset, destZoomLevel);
        _modifyDestPanOffset('y', destPanBounds, destPanOffset, destZoomLevel);

        var initialZoomLevel = _currZoomLevel;
        var initialPanOffset = {
            x: _panOffset.x,
            y: _panOffset.y,
        };

        _roundPoint(destPanOffset);

        var onUpdate = function (now) {
            if (now === 1) {
                _currZoomLevel = destZoomLevel;
                _panOffset.x = destPanOffset.x;
                _panOffset.y = destPanOffset.y;
            } else {
                _currZoomLevel =
                    (destZoomLevel - initialZoomLevel) * now + initialZoomLevel;
                _panOffset.x =
                    (destPanOffset.x - initialPanOffset.x) * now +
                    initialPanOffset.x;
                _panOffset.y =
                    (destPanOffset.y - initialPanOffset.y) * now +
                    initialPanOffset.y;
            }

            if (updateFn) {
                updateFn(now);
            }

            _applyCurrentZoomPan(now === 1);
        };

        if (speed) {
            _animateProp(
                'customZoomTo',
                0,
                1,
                speed,
                easingFn || framework.easing.sine.inOut,
                onUpdate
            );
        } else {
            onUpdate(1);
        }
    },
};
