/**
 *
 * Controller manages gallery items, their dimensions, and their content.
 *
 */

var _items,
    _tempPanAreaSize = {},
    _imagesToAppendPool = [],
    _initialContentSet,
    _initialZoomRunning,
    _controllerDefaultOptions = {
        index: 0,
        errorMsg:
            '<div class="pswp__error-msg"><a href="%url%" target="_blank">The image</a> could not be loaded.</div>',
        forceProgressiveLoading: false, // TODO
        preload: [1, 1],
        getNumItemsFn: function () {
            return _items.length;
        },
    };

var _getItemAt,
    _getNumItems,
    _initialIsLoop,
    _getZeroBounds = function () {
        return {
            center: { x: 0, y: 0 },
            max: { x: 0, y: 0 },
            min: { x: 0, y: 0 },
        };
    },
    _calculateSingleItemPanBounds = function (
        item,
        realPanElementW,
        realPanElementH
    ) {
        var bounds = item.bounds;

        // position of element when it's centered
        bounds.center.x = Math.round(
            (_tempPanAreaSize.x - realPanElementW) / 2
        );
        bounds.center.y =
            Math.round((_tempPanAreaSize.y - realPanElementH) / 2) +
            item.vGap.top;

        // maximum pan position
        bounds.max.x =
            realPanElementW > _tempPanAreaSize.x
                ? Math.round(_tempPanAreaSize.x - realPanElementW)
                : bounds.center.x;

        bounds.max.y =
            realPanElementH > _tempPanAreaSize.y
                ? Math.round(_tempPanAreaSize.y - realPanElementH) +
                  item.vGap.top
                : bounds.center.y;

        // minimum pan position
        bounds.min.x =
            realPanElementW > _tempPanAreaSize.x ? 0 : bounds.center.x;
        bounds.min.y =
            realPanElementH > _tempPanAreaSize.y
                ? item.vGap.top
                : bounds.center.y;
    },
    _calculateItemSize = function (item, viewportSize, zoomLevel) {
        if (item.src && !item.loadError) {
            var isInitial = !zoomLevel;

            if (isInitial) {
                if (!item.vGap) {
                    item.vGap = { top: 0, bottom: 0 };
                }
                // allows overriding vertical margin for individual items
                _shout('parseVerticalMargin', item);
            }

            _tempPanAreaSize.x = viewportSize.x;
            _tempPanAreaSize.y =
                viewportSize.y - item.vGap.top - item.vGap.bottom;

            if (isInitial) {
                var hRatio = _tempPanAreaSize.x / item.w;
                var vRatio = _tempPanAreaSize.y / item.h;

                item.fitRatio = hRatio < vRatio ? hRatio : vRatio;
                //item.fillRatio = hRatio > vRatio ? hRatio : vRatio;

                var scaleMode = _options.scaleMode;

                if (scaleMode === 'orig') {
                    zoomLevel = 1;
                } else if (scaleMode === 'fit') {
                    zoomLevel = item.fitRatio;
                }

                if (zoomLevel > 1) {
                    zoomLevel = 1;
                }

                item.initialZoomLevel = zoomLevel;

                if (!item.bounds) {
                    // reuse bounds object
                    item.bounds = _getZeroBounds();
                }
            }

            if (!zoomLevel) {
                return;
            }

            _calculateSingleItemPanBounds(
                item,
                item.w * zoomLevel,
                item.h * zoomLevel
            );

            if (isInitial && zoomLevel === item.initialZoomLevel) {
                item.initialPosition = item.bounds.center;
            }

            return item.bounds;
        } else {
            item.w = item.h = 0;
            item.initialZoomLevel = item.fitRatio = 1;
            item.bounds = _getZeroBounds();
            item.initialPosition = item.bounds.center;

            // if it's not image, we return zero bounds (content is not zoomable)
            return item.bounds;
        }
    },
    _appendImage = function (
        index,
        item,
        baseDiv,
        img,
        preventAnimation,
        keepPlaceholder
    ) {
        if (item.loadError) {
            return;
        }

        if (img) {
            item.imageAppended = true;
            _setImageSize(
                item,
                img,
                item === self.currItem && _renderMaxResolution
            );

            baseDiv.appendChild(img);

            if (keepPlaceholder) {
                setTimeout(function () {
                    if (item && item.loaded && item.placeholder) {
                        item.placeholder.style.display = 'none';
                        item.placeholder = null;
                    }
                }, 500);
            }
        }
    },
    _preloadImage = function (item) {
        item.loading = true;
        item.loaded = false;
        var img = (item.img = framework.createEl('pswp__img', 'img'));
        img.oncontextmenu=(e)=>e.preventDefault();
        var onComplete = function () {
            item.loading = false;
            item.loaded = true;

            if (item.loadComplete) {
                item.loadComplete(item);
            } else {
                item.img = null; // no need to store image object
            }
            img.onload = img.onerror = null;
            img = null;
        };
        img.onload = onComplete;
        img.onerror = function () {
            item.loadError = true;
            onComplete();
        };

        img.src = item.src; // + '?a=' + Math.random();

        return img;
    },
    _checkForError = function (item, cleanUp) {
        if (item.src && item.loadError && item.container) {
            if (cleanUp) {
                item.container.innerHTML = '';
            }

            item.container.innerHTML = _options.errorMsg.replace(
                '%url%',
                item.src
            );
            return true;
        }
    },
    _setImageSize = function (item, img, maxRes) {
        if (!item.src || !item.container) {
            return;
        }

        if (!img) {
            img = item.container.lastChild;
        }

        var w = maxRes ? item.w : Math.round(item.w * item.fitRatio),
            h = maxRes ? item.h : Math.round(item.h * item.fitRatio);

        if (item.placeholder && !item.loaded) {
            item.placeholder.style.width = w + 'px';
            item.placeholder.style.height = h + 'px';
        }

        img.style.width = w + 'px';
        img.style.height = h + 'px';
    },
    _appendImagesPool = function () {
        if (_imagesToAppendPool.length) {
            var poolItem;

            for (var i = 0; i < _imagesToAppendPool.length; i++) {
                poolItem = _imagesToAppendPool[i];
                if (poolItem.holder.index === poolItem.index) {
                    _appendImage(
                        poolItem.index,
                        poolItem.item,
                        poolItem.baseDiv,
                        poolItem.img,
                        false,
                        poolItem.clearPlaceholder
                    );
                }
            }
            _imagesToAppendPool = [];
        }
    };

_registerModule('Controller', {
    publicMethods: {
        lazyLoadItem: function (index) {
            index = _getLoopedId(index);
            var item = _getItemAt(index);
            if (!item || ((item.loaded || item.loading) && !_itemsNeedUpdate)) {
                return;
            }

            _shout('gettingData', index, item);

            if (!item.src) {
                return;
            }

            _preloadImage(item);
        },
        initController: function () {
            framework.extend(_options, _controllerDefaultOptions, true);
            self.items = _items = items;
            _getItemAt = self.getItemAt;
            _getNumItems = _options.getNumItemsFn; //self.getNumItems;

            _initialIsLoop = _options.loop;
            if (_getNumItems() < 3) {
                _options.loop = false; // disable loop if less then 3 items
            }

            _listen('beforeChange', function (diff) {
                self.lazyLoadItem(_currentItemIndex);
            });

            _listen('initialLayout', function () {
                self.currItem.initialLayout =
                    _options.getThumbBoundsFn &&
                    _options.getThumbBoundsFn(_currentItemIndex);
            });

            _listen('mainScrollAnimComplete', _appendImagesPool);
            _listen('initialZoomInEnd', _appendImagesPool);

            _listen('destroy', function () {
                var item;
                for (var i = 0; i < _items.length; i++) {
                    item = _items[i];
                    // remove reference to DOM elements, for GC
                    if (item.container) {
                        item.container = null;
                    }
                    if (item.placeholder) {
                        item.placeholder = null;
                    }
                    if (item.img) {
                        item.img = null;
                    }
                    if (item.preloader) {
                        item.preloader = null;
                    }
                    if (item.loadError) {
                        item.loaded = item.loadError = false;
                    }
                }
                _imagesToAppendPool = null;
            });
        },

        getItemAt: function (index) {
            if (index >= 0) {
                return _items[index] !== undefined ? _items[index] : false;
            }
            return false;
        },

        allowProgressiveImg: function () {
            // 1. Progressive image loading isn't working on webkit/blink
            //    when hw-acceleration (e.g. translateZ) is applied to IMG element.
            //    That's why in PhotoSwipe parent element gets zoom transform, not image itself.
            //
            // 2. Progressive image loading sometimes blinks in webkit/blink when applying animation to parent element.
            //    That's why it's disabled on touch devices (mainly because of swipe transition)
            //
            // 3. Progressive image loading sometimes doesn't work in IE (up to 11).

            // Don't allow progressive loading on non-large touch devices
            return (
                _options.forceProgressiveLoading ||
                !_likelyTouchDevice ||
                _options.mouseUsed ||
                screen.width > 1200
            );
            // 1200 - to eliminate touch devices with large screen (like Chromebook Pixel)
        },

        setContent: function (holder, index) {
            if (_options.loop) {
                index = _getLoopedId(index);
            }

            var prevItem = self.getItemAt(holder.index);
            if (prevItem) {
                prevItem.container = null;
            }

            var item = self.getItemAt(index),
                img;

            if (!item) {
                holder.el.innerHTML = '';
                return;
            }

            // allow to override data
            if (index === _currentItemIndex) {
                _shout('gettingData', index, item);
            }

            holder.index = index;
            holder.item = item;

            // base container DIV is created only once for each of 3 holders
            var baseDiv = (item.container =
                framework.createEl('pswp__zoom-wrap'));

            if (!item.src && item.html) {
                if (item.html.tagName) {
                    baseDiv.appendChild(item.html);
                } else {
                    baseDiv.innerHTML = item.html;
                }
            }

            _checkForError(item);

            _calculateItemSize(item, _viewportSize);

            if (item.src && !item.loadError && !item.loaded) {
                item.loadComplete = function (item) {
                    // gallery closed before image finished loading
                    if (!_isOpen) {
                        return;
                    }

                    // check if holder hasn't changed while image was loading
                    if (holder && holder.index === index) {
                        if (_checkForError(item, true)) {
                            item.loadComplete = item.img = null;
                            _calculateItemSize(item, _viewportSize);
                            _applyZoomPanToItem(item);

                            if (holder.index === _currentItemIndex) {
                                // recalculate dimensions
                                self.updateCurrZoomItem();
                            }
                            return;
                        }
                        if (!item.imageAppended) {
                            if (
                                _features.transform &&
                                (_mainScrollAnimating || _initialZoomRunning)
                            ) {
                                _imagesToAppendPool.push({
                                    item: item,
                                    baseDiv: baseDiv,
                                    img: item.img,
                                    index: index,
                                    holder: holder,
                                    clearPlaceholder: true,
                                });
                            } else {
                                _appendImage(
                                    index,
                                    item,
                                    baseDiv,
                                    item.img,
                                    _mainScrollAnimating || _initialZoomRunning,
                                    true
                                );
                            }
                        } else {
                            // remove preloader & mini-img
                            if (!_initialZoomRunning && item.placeholder) {
                                item.placeholder.style.display = 'none';
                                item.placeholder = null;
                            }
                        }
                    }

                    item.loadComplete = null;
                    item.img = null; // no need to store image element after it's added

                    _shout('imageLoadComplete', index, item);
                };

                if (framework.features.transform) {
                    var placeholderClassName =
                        'pswp__img pswp__img--placeholder';
                    placeholderClassName += item.msrc
                        ? ''
                        : ' pswp__img--placeholder--blank';

                    var placeholder = framework.createEl(
                        placeholderClassName,
                        item.msrc ? 'img' : ''
                    );
                    placeholder.oncontextmenu=(e)=>e.preventDefault();
                    if (item.msrc) {
                        placeholder.src = item.msrc;
                    }

                    _setImageSize(item, placeholder);

                    baseDiv.appendChild(placeholder);
                    item.placeholder = placeholder;
                }

                if (self.allowProgressiveImg()) {
                    // just append image
                    if (!_initialContentSet && _features.transform) {
                        _imagesToAppendPool.push({
                            item: item,
                            baseDiv: baseDiv,
                            img: item.img,
                            index: index,
                            holder: holder,
                        });
                    } else {
                        _appendImage(
                            index,
                            item,
                            baseDiv,
                            item.img,
                            true,
                            true
                        );
                    }
                }
            } else if (item.src && !item.loadError) {
                // image object is created every time, due to bugs of image loading & delay when switching images
                img = framework.createEl('pswp__img', 'img');
                img.style.opacity = 1;
                img.src = item.src;
                img.oncontextmenu=(e)=>e.preventDefault();
                _setImageSize(item, img);
                _appendImage(index, item, baseDiv, img, true);
            }

            if (!_initialContentSet && index === _currentItemIndex) {
                _currZoomElementStyle = baseDiv.style;
                if (!item.initialPosition) {
                    item.initialPosition = { x: 48, y: 44 };
                    item.bounds = {
                        center: {
                            x: 48,
                            y: 44,
                        },
                        max: {
                            x: 48,
                            y: 44,
                        },
                        min: {
                            x: 48,
                            y: 44,
                        },
                    };
                    item.h = window.innerHeight;
                    item.w = window.innerWidth;
                    item.fitRatio = 0.9067796610169492;
                    item.initialZoomLevel = 0.9067796610169492;
                }
                _showOrHide(item, img || item.img);
            } else {
                _applyZoomPanToItem(item);
            }

            holder.el.innerHTML = '';
            holder.el.appendChild(baseDiv);
        },

        cleanSlide: function (item) {
            if (item.img) {
                item.img.onload = item.img.onerror = null;
            }
            item.loaded = item.loading = item.img = item.imageAppended = false;
        },
    },
});
