/**
 * show-hide-transition.js:
 *
 * Manages initial opening or closing transition.
 *
 * If you're not planning to use transition for gallery at all,
 * you may set options hideAnimationDuration and showAnimationDuration to 0,
 * and just delete startAnimation function.
 *
 */

var _showOrHideTimeout,
    _showOrHide = function (item, img, out, completeFn) {
        if (_showOrHideTimeout) {
            clearTimeout(_showOrHideTimeout);
        }

        _initialZoomRunning = true;
        _initialContentSet = true;

        // dimensions of small thumbnail {x:,y:,w:}.
        // Height is optional, as calculated based on large image.
        var thumbBounds;
        if (item.initialLayout) {
            thumbBounds = item.initialLayout;
            item.initialLayout = null;
        } else {
            thumbBounds =
                _options.getThumbBoundsFn &&
                _options.getThumbBoundsFn(_currentItemIndex);
        }

        var duration = out
            ? _options.hideAnimationDuration
            : _options.showAnimationDuration;

        var onComplete = function () {
            _stopAnimation('initialZoom');
            if (!out) {
                _applyBgOpacity(1);
                if (img) {
                    img.style.display = 'block';
                }
                framework.addClass(template, 'pswp--animated-in');
                _shout('initialZoom' + (out ? 'OutEnd' : 'InEnd'));
            } else {
                self.template.removeAttribute('style');
                self.bg.removeAttribute('style');
            }

            if (completeFn) {
                completeFn();
            }
            _initialZoomRunning = false;
        };

        // if bounds aren't provided, just open gallery without animation
        if (!duration || !thumbBounds || thumbBounds.x === undefined) {
            _shout('initialZoom' + (out ? 'Out' : 'In'));

            _currZoomLevel = item.initialZoomLevel;
            _equalizePoints(_panOffset, item.initialPosition);
            _applyCurrentZoomPan();

            template.style.opacity = out ? 0 : 1;
            _applyBgOpacity(1);

            if (duration) {
                setTimeout(function () {
                    onComplete();
                }, duration);
            } else {
                onComplete();
            }

            return;
        }

        var startAnimation = function () {
            var closeWithRaf = _closedByScroll,
                fadeEverything =
                    !self.currItem.src ||
                    self.currItem.loadError ||
                    _options.showHideOpacity;

            // apply hw-acceleration to image
            if (item.miniImg) {
                item.miniImg.style.webkitBackfaceVisibility = 'hidden';
            }

            if (!out) {
                _currZoomLevel = thumbBounds.w / item.w;
                _panOffset.x = thumbBounds.x;
                _panOffset.y = thumbBounds.y - _initalWindowScrollY;

                self[fadeEverything ? 'template' : 'bg'].style.opacity = 0.001;
                _applyCurrentZoomPan();
            }

            _registerStartAnimation('initialZoom');

            if (out && !closeWithRaf) {
                framework.removeClass(template, 'pswp--animated-in');
            }

            if (fadeEverything) {
                if (out) {
                    framework[(closeWithRaf ? 'remove' : 'add') + 'Class'](
                        template,
                        'pswp--animate_opacity'
                    );
                } else {
                    setTimeout(function () {
                        framework.addClass(template, 'pswp--animate_opacity');
                    }, 30);
                }
            }

            _showOrHideTimeout = setTimeout(
                function () {
                    _shout('initialZoom' + (out ? 'Out' : 'In'));

                    if (!out) {
                        // "in" animation always uses CSS transitions (instead of rAF).
                        // CSS transition work faster here,
                        // as developer may also want to animate other things,
                        // like ui on top of sliding area, which can be animated just via CSS

                        _currZoomLevel = item.initialZoomLevel;
                        _equalizePoints(_panOffset, item.initialPosition);
                        _applyCurrentZoomPan();
                        _applyBgOpacity(1);

                        if (fadeEverything) {
                            template.style.opacity = 1;
                        } else {
                            _applyBgOpacity(1);
                        }

                        _showOrHideTimeout = setTimeout(
                            onComplete,
                            duration + 20
                        );
                    } else {
                        // "out" animation uses rAF only when PhotoSwipe is closed by browser scroll, to recalculate position
                        var destZoomLevel = thumbBounds.w / item.w,
                            initialPanOffset = {
                                x: _panOffset.x,
                                y: _panOffset.y,
                            },
                            initialZoomLevel = _currZoomLevel,
                            initalBgOpacity = _bgOpacity,
                            onUpdate = function (now) {
                                if (now === 1) {
                                    _currZoomLevel = destZoomLevel;
                                    _panOffset.x = thumbBounds.x;
                                    _panOffset.y =
                                        thumbBounds.y - _currentWindowScrollY;
                                } else {
                                    _currZoomLevel =
                                        (destZoomLevel - initialZoomLevel) *
                                            now +
                                        initialZoomLevel;
                                    _panOffset.x =
                                        (thumbBounds.x - initialPanOffset.x) *
                                            now +
                                        initialPanOffset.x;
                                    _panOffset.y =
                                        (thumbBounds.y -
                                            _currentWindowScrollY -
                                            initialPanOffset.y) *
                                            now +
                                        initialPanOffset.y;
                                }

                                _applyCurrentZoomPan();
                                if (fadeEverything) {
                                    template.style.opacity = 1 - now;
                                } else {
                                    _applyBgOpacity(
                                        initalBgOpacity - now * initalBgOpacity
                                    );
                                }
                            };

                        if (closeWithRaf) {
                            _animateProp(
                                'initialZoom',
                                0,
                                1,
                                duration,
                                framework.easing.cubic.out,
                                onUpdate,
                                onComplete
                            );
                        } else {
                            onUpdate(1);
                            _showOrHideTimeout = setTimeout(
                                onComplete,
                                duration + 20
                            );
                        }
                    }
                },
                out ? 25 : 90
            ); // Main purpose of this delay is to give browser time to paint and
            // create composite layers of PhotoSwipe UI parts (background, controls, caption, arrows).
            // Which avoids lag at the beginning of scale transition.
        };
        startAnimation();
    };
