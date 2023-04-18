/**
 *
 * history.js:
 *
 * - Back button to close gallery.
 *
 * - Unique URL for each slide: example.com/&pid=1&gid=3
 *   (where PID is picture index, and GID and gallery index)
 *
 * - Switch URL when slides change.
 *
 */

var _historyDefaultOptions = {
    history: true,
    galleryUID: 1,
};

var _historyUpdateTimeout,
    _hashChangeTimeout,
    _hashAnimCheckTimeout,
    _hashChangedByScript,
    _hashChangedByHistory,
    _hashReseted,
    _initialHash,
    _historyChanged,
    _closedFromURL,
    _urlChangedOnce,
    _windowLoc,
    _supportsPushState,
    _getHash = function () {
        return _windowLoc.hash.substring(1);
    },
    _cleanHistoryTimeouts = function () {
        if (_historyUpdateTimeout) {
            clearTimeout(_historyUpdateTimeout);
        }

        if (_hashAnimCheckTimeout) {
            clearTimeout(_hashAnimCheckTimeout);
        }
    },
    // pid - Picture index
    // gid - Gallery index
    _parseItemIndexFromURL = function () {
        var hash = _getHash(),
            params = {};

        if (hash.length < 5) {
            // pid=1
            return params;
        }

        var i,
            vars = hash.split('&');
        for (i = 0; i < vars.length; i++) {
            if (!vars[i]) {
                continue;
            }
            var pair = vars[i].split('=');
            if (pair.length < 2) {
                continue;
            }
            params[pair[0]] = pair[1];
        }
        if (_options.galleryPIDs) {
            // detect custom pid in hash and search for it among the items collection
            var searchfor = params.pid;
            params.pid = 0; // if custom pid cannot be found, fallback to the first item
            for (i = 0; i < _items.length; i++) {
                if (_items[i].pid === searchfor) {
                    params.pid = i;
                    break;
                }
            }
        } else {
            params.pid = parseInt(params.pid, 10) - 1;
        }
        if (params.pid < 0) {
            params.pid = 0;
        }
        return params;
    },
    _updateHash = function () {
        if (_hashAnimCheckTimeout) {
            clearTimeout(_hashAnimCheckTimeout);
        }

        if (_numAnimations || _isDragging) {
            // changing browser URL forces layout/paint in some browsers, which causes noticable lag during animation
            // that's why we update hash only when no animations running
            _hashAnimCheckTimeout = setTimeout(_updateHash, 500);
            return;
        }

        if (_hashChangedByScript) {
            clearTimeout(_hashChangeTimeout);
        } else {
            _hashChangedByScript = true;
        }

        var pid = _currentItemIndex + 1;
        var item = _getItemAt(_currentItemIndex);
        if (item.hasOwnProperty('pid')) {
            // carry forward any custom pid assigned to the item
            pid = item.pid;
        }
        var newHash =
            _initialHash +
            '&' +
            'gid=' +
            _options.galleryUID +
            '&' +
            'pid=' +
            pid;

        if (!_historyChanged) {
            if (_windowLoc.hash.indexOf(newHash) === -1) {
                _urlChangedOnce = true;
            }
            // first time - add new hisory record, then just replace
        }

        var newURL = _windowLoc.href.split('#')[0] + '#' + newHash;

        if (_supportsPushState) {
            if ('#' + newHash !== window.location.hash) {
                history[_historyChanged ? 'replaceState' : 'pushState'](
                    '',
                    document.title,
                    newURL
                );
            }
        } else {
            if (_historyChanged) {
                _windowLoc.replace(newURL);
            } else {
                _windowLoc.hash = newHash;
            }
        }

        _historyChanged = true;
        _hashChangeTimeout = setTimeout(function () {
            _hashChangedByScript = false;
        }, 60);
    };

_registerModule('History', {
    publicMethods: {
        initHistory: function () {
            framework.extend(_options, _historyDefaultOptions, true);

            if (!_options.history) {
                return;
            }

            _windowLoc = window.location;
            _urlChangedOnce = false;
            _closedFromURL = false;
            _historyChanged = false;
            _initialHash = _getHash();
            _supportsPushState = 'pushState' in history;

            if (_initialHash.indexOf('gid=') > -1) {
                _initialHash = _initialHash.split('&gid=')[0];
                _initialHash = _initialHash.split('?gid=')[0];
            }

            _listen('afterChange', self.updateURL);
            _listen('unbindEvents', function () {
                framework.unbind(window, 'hashchange', self.onHashChange);
            });

            var returnToOriginal = function () {
                _hashReseted = true;
                if (!_closedFromURL) {
                    if (_urlChangedOnce) {
                        history.back();
                    } else {
                        if (_initialHash) {
                            _windowLoc.hash = _initialHash;
                        } else {
                            if (_supportsPushState) {
                                // remove hash from url without refreshing it or scrolling to top
                                history.pushState(
                                    '',
                                    document.title,
                                    _windowLoc.pathname + _windowLoc.search
                                );
                            } else {
                                _windowLoc.hash = '';
                            }
                        }
                    }
                }

                _cleanHistoryTimeouts();
            };

            _listen('unbindEvents', function () {
                if (_closedByScroll) {
                    // if PhotoSwipe is closed by scroll, we go "back" before the closing animation starts
                    // this is done to keep the scroll position
                    returnToOriginal();
                }
            });
            _listen('destroy', function () {
                if (!_hashReseted) {
                    returnToOriginal();
                }
            });
            _listen('firstUpdate', function () {
                _currentItemIndex = _parseItemIndexFromURL().pid;
            });

            var index = _initialHash.indexOf('pid=');
            if (index > -1) {
                _initialHash = _initialHash.substring(0, index);
                if (_initialHash.slice(-1) === '&') {
                    _initialHash = _initialHash.slice(0, -1);
                }
            }

            setTimeout(function () {
                if (_isOpen) {
                    // hasn't destroyed yet
                    framework.bind(window, 'hashchange', self.onHashChange);
                }
            }, 40);
        },
        onHashChange: function () {
            if (_getHash() === _initialHash) {
                _closedFromURL = true;
                self.close();
                return;
            }
            if (!_hashChangedByScript) {
                _hashChangedByHistory = true;
                self.goTo(_parseItemIndexFromURL().pid);
                _hashChangedByHistory = false;
            }
        },
        updateURL: function () {
            // Delay the update of URL, to avoid lag during transition,
            // and to not to trigger actions like "refresh page sound" or "blinking favicon" to often

            _cleanHistoryTimeouts();

            if (_hashChangedByHistory) {
                return;
            }

            if (!_historyChanged) {
                _updateHash(); // first time
            } else {
                _historyUpdateTimeout = setTimeout(_updateHash, 800);
            }
        },
    },
});
