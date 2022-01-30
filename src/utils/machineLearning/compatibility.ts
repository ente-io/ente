import {
    offscreenCanvasSupported,
    runningInChrome,
    webglSupported,
} from 'utils/common';

// TODO: check electron env to be campatible with this
export function canEnableMlSearch(): boolean {
    if (!runningInChrome(false)) {
        console.log('Not running in Chrome Desktop');
        return false;
    }

    if (!offscreenCanvasSupported()) {
        console.log('OffscreenCanvas is NOT supported');
        return false;
    }

    if (!webglSupported()) {
        console.log('webgl is NOT supported');
        return false;
    }

    return true;
}
