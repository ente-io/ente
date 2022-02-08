import {
    offscreenCanvasSupported,
    runningInChrome,
    webglSupported,
} from 'utils/common';

import isElectron from 'is-electron';

export function canEnableMlSearch(): boolean {
    // check if is chrome or ente desktop
    if (!runningInChrome(false) && !isElectron()) {
        console.log('Not running in Chrome Desktop or Ente Desktop App');
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
