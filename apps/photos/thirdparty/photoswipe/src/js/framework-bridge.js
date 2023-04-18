/**
 *
 * Set of generic functions used by gallery.
 *
 * You're free to modify anything here as long as functionality is kept.
 *
 */
var framework = {
    features: null,
    bind: function (target, type, listener, unbind) {
        var methodName = (unbind ? 'remove' : 'add') + 'EventListener';
        type = type.split(' ');
        for (var i = 0; i < type.length; i++) {
            if (type[i]) {
                target[methodName](type[i], listener, false);
            }
        }
    },
    isArray: function (obj) {
        return obj instanceof Array;
    },
    createEl: function (classes, tag) {
        var el = document.createElement(tag || 'div');
        if (classes) {
            el.className = classes;
        }
        return el;
    },
    getScrollY: function () {
        var yOffset = window.pageYOffset;
        return yOffset !== undefined
            ? yOffset
            : document.documentElement.scrollTop;
    },
    unbind: function (target, type, listener) {
        framework.bind(target, type, listener, true);
    },
    removeClass: function (el, className) {
        var reg = new RegExp('(\\s|^)' + className + '(\\s|$)');
        el.className = el.className
            .replace(reg, ' ')
            .replace(/^\s\s*/, '')
            .replace(/\s\s*$/, '');
    },
    addClass: function (el, className) {
        if (!framework.hasClass(el, className)) {
            el.className += (el.className ? ' ' : '') + className;
        }
    },
    hasClass: function (el, className) {
        return (
            el.className &&
            new RegExp('(^|\\s)' + className + '(\\s|$)').test(el.className)
        );
    },
    getChildByClass: function (parentEl, childClassName) {
        var node = parentEl.firstChild;
        while (node) {
            if (framework.hasClass(node, childClassName)) {
                return node;
            }
            node = node.nextSibling;
        }
    },
    arraySearch: function (array, value, key) {
        var i = array.length;
        while (i--) {
            if (array[i][key] === value) {
                return i;
            }
        }
        return -1;
    },
    extend: function (o1, o2, preventOverwrite) {
        for (var prop in o2) {
            if (o2.hasOwnProperty(prop)) {
                if (preventOverwrite && o1.hasOwnProperty(prop)) {
                    continue;
                }
                o1[prop] = o2[prop];
            }
        }
    },
    easing: {
        sine: {
            out: function (k) {
                return Math.sin(k * (Math.PI / 2));
            },
            inOut: function (k) {
                return -(Math.cos(Math.PI * k) - 1) / 2;
            },
        },
        cubic: {
            out: function (k) {
                return --k * k * k + 1;
            },
        },
        /*
			elastic: {
				out: function ( k ) {

					var s, a = 0.1, p = 0.4;
					if ( k === 0 ) return 0;
					if ( k === 1 ) return 1;
					if ( !a || a < 1 ) { a = 1; s = p / 4; }
					else s = p * Math.asin( 1 / a ) / ( 2 * Math.PI );
					return ( a * Math.pow( 2, - 10 * k) * Math.sin( ( k - s ) * ( 2 * Math.PI ) / p ) + 1 );

				},
			},
			back: {
				out: function ( k ) {
					var s = 1.70158;
					return --k * k * ( ( s + 1 ) * k + s ) + 1;
				}
			}
		*/
    },

    /**
     *
     * @return {object}
     *
     * {
     *  raf : request animation frame function
     *  caf : cancel animation frame function
     *  transfrom : transform property key (with vendor), or null if not supported
     *  oldIE : IE8 or below
     * }
     *
     */
    detectFeatures: function () {
        if (framework.features) {
            return framework.features;
        }
        var helperEl = framework.createEl(),
            helperStyle = helperEl.style,
            vendor = '',
            features = {};

        // IE8 and below
        features.oldIE = document.all && !document.addEventListener;

        features.touch = 'ontouchstart' in window;

        if (window.requestAnimationFrame) {
            features.raf = window.requestAnimationFrame;
            features.caf = window.cancelAnimationFrame;
        }

        features.pointerEvent =
            !!window.PointerEvent || navigator.msPointerEnabled;

        // fix false-positive detection of old Android in new IE
        // (IE11 ua string contains "Android 4.0")

        if (!features.pointerEvent) {
            var ua = navigator.userAgent;

            // Detect if device is iPhone or iPod and if it's older than iOS 8
            // http://stackoverflow.com/a/14223920
            //
            // This detection is made because of buggy top/bottom toolbars
            // that don't trigger window.resize event.
            // For more info refer to _isFixedPosition variable in core.js

            if (/iP(hone|od)/.test(navigator.platform)) {
                var v = navigator.appVersion.match(/OS (\d+)_(\d+)_?(\d+)?/);
                if (v && v.length > 0) {
                    v = parseInt(v[1], 10);
                    if (v >= 1 && v < 8) {
                        features.isOldIOSPhone = true;
                    }
                }
            }

            // Detect old Android (before KitKat)
            // due to bugs related to position:fixed
            // http://stackoverflow.com/questions/7184573/pick-up-the-android-version-in-the-browser-by-javascript

            var match = ua.match(/Android\s([0-9\.]*)/);
            var androidversion = match ? match[1] : 0;
            androidversion = parseFloat(androidversion);
            if (androidversion >= 1) {
                if (androidversion < 4.4) {
                    features.isOldAndroid = true; // for fixed position bug & performance
                }
                features.androidVersion = androidversion; // for touchend bug
            }
            features.isMobileOpera = /opera mini|opera mobi/i.test(ua);

            // p.s. yes, yes, UA sniffing is bad, propose your solution for above bugs.
        }

        var styleChecks = ['transform', 'perspective', 'animationName'],
            vendors = ['', 'webkit', 'Moz', 'ms', 'O'],
            styleCheckItem,
            styleName;

        for (var i = 0; i < 4; i++) {
            vendor = vendors[i];

            for (var a = 0; a < 3; a++) {
                styleCheckItem = styleChecks[a];

                // uppercase first letter of property name, if vendor is present
                styleName =
                    vendor +
                    (vendor
                        ? styleCheckItem.charAt(0).toUpperCase() +
                          styleCheckItem.slice(1)
                        : styleCheckItem);

                if (!features[styleCheckItem] && styleName in helperStyle) {
                    features[styleCheckItem] = styleName;
                }
            }

            if (vendor && !features.raf) {
                vendor = vendor.toLowerCase();
                features.raf = window[vendor + 'RequestAnimationFrame'];
                if (features.raf) {
                    features.caf =
                        window[vendor + 'CancelAnimationFrame'] ||
                        window[vendor + 'CancelRequestAnimationFrame'];
                }
            }
        }

        if (!features.raf) {
            var lastTime = 0;
            features.raf = function (fn) {
                var currTime = new Date().getTime();
                var timeToCall = Math.max(0, 16 - (currTime - lastTime));
                var id = window.setTimeout(function () {
                    fn(currTime + timeToCall);
                }, timeToCall);
                lastTime = currTime + timeToCall;
                return id;
            };
            features.caf = function (id) {
                clearTimeout(id);
            };
        }

        // Detect SVG support
        features.svg =
            !!document.createElementNS &&
            !!document.createElementNS('http://www.w3.org/2000/svg', 'svg')
                .createSVGRect;

        framework.features = features;

        return features;
    },
};

framework.detectFeatures();

// Override addEventListener for old versions of IE
if (framework.features.oldIE) {
    framework.bind = function (target, type, listener, unbind) {
        type = type.split(' ');

        var methodName = (unbind ? 'detach' : 'attach') + 'Event',
            evName,
            _handleEv = function () {
                listener.handleEvent.call(listener);
            };

        for (var i = 0; i < type.length; i++) {
            evName = type[i];
            if (evName) {
                if (typeof listener === 'object' && listener.handleEvent) {
                    if (!unbind) {
                        listener['oldIE' + evName] = _handleEv;
                    } else {
                        if (!listener['oldIE' + evName]) {
                            return false;
                        }
                    }

                    target[methodName](
                        'on' + evName,
                        listener['oldIE' + evName]
                    );
                } else {
                    target[methodName]('on' + evName, listener);
                }
            }
        }
    };
}
