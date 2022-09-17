import constants from 'utils/strings/constants';
import { CustomError } from 'utils/error';
import GetDeviceOS, { OS } from './deviceDetection';
import isElectron from 'is-electron';

const DESKTOP_APP_GITHUB_DOWNLOAD_URL =
    'https://github.com/ente-io/bhari-frame/releases/latest';

const APP_DOWNLOAD_ENTE_URL_PREFIX = 'https://ente.io/download';

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    }
    throw new Error(constants.NO_INTERNET_CONNECTION);
}

export function runningInBrowser() {
    return typeof window !== 'undefined';
}

export function runningInWorker() {
    return typeof importScripts === 'function';
}

export function runningInElectron() {
    return isElectron();
}

export function runningInChrome(includeMobile: boolean) {
    try {
        const userAgentData = navigator['userAgentData'];
        const chromeBrand = userAgentData?.brands?.filter(
            (b) => b.brand === 'Google Chrome' || b.brand === 'Chromium'
        )?.[0];
        return chromeBrand && (includeMobile || userAgentData.mobile === false);
    } catch (error) {
        console.error('Error in runningInChrome: ', error);
        return false;
    }
}

export function offscreenCanvasSupported() {
    return !(typeof OffscreenCanvas === 'undefined');
}

export function webglSupported() {
    try {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl');
        return gl && gl instanceof WebGLRenderingContext;
    } catch (error) {
        console.error('Error in webglSupported: ', error);
        return false;
    }
}

export async function sleep(time: number) {
    await new Promise((resolve) => {
        setTimeout(() => resolve(null), time);
    });
}

export function getOSSpecificDesktopAppDownloadLink() {
    const os = GetDeviceOS();
    let url = '';
    if (os === OS.WINDOWS) {
        url = `${APP_DOWNLOAD_ENTE_URL_PREFIX}/exe`;
    } else if (os === OS.MAC) {
        url = `${APP_DOWNLOAD_ENTE_URL_PREFIX}/dmg`;
    } else {
        url = DESKTOP_APP_GITHUB_DOWNLOAD_URL;
    }
    return url;
}
export function downloadApp() {
    const link = getOSSpecificDesktopAppDownloadLink();
    const win = window.open(link, '_blank');
    win.focus();
}

export function reverseString(title: string) {
    return title
        ?.split(' ')
        .reduce((reversedString, currWord) => `${currWord} ${reversedString}`);
}

export function initiateEmail(email: string) {
    const a = document.createElement('a');
    a.href = 'mailto:' + email;
    a.rel = 'noreferrer noopener';
    a.click();
}
export const promiseWithTimeout = async (
    request: Promise<any>,
    timeout: number
) => {
    const timeoutRef = { current: null };
    const rejectOnTimeout = new Promise((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            timeout
        );
    });
    const requestWithTimeOutCancellation = async () => {
        const resp = await request;
        clearTimeout(timeoutRef.current);
        return resp;
    };
    return await Promise.race([
        requestWithTimeOutCancellation(),
        rejectOnTimeout,
    ]);
};

export const preloadImage = (imgBasePath: string) => {
    const srcSet = [];
    for (let i = 1; i <= 3; i++) {
        srcSet.push(`${imgBasePath}/${i}x.png ${i}x`);
    }
    new Image().srcset = srcSet.join(',');
};
export function openLink(href: string, newTab?: boolean) {
    const a = document.createElement('a');
    a.href = href;
    if (newTab) {
        a.target = '_blank';
    }
    a.rel = 'noreferrer noopener';
    a.click();
}

export async function waitAndRun(
    waitPromise: Promise<void>,
    task: () => Promise<void>
) {
    if (waitPromise && isPromise(waitPromise)) {
        await waitPromise;
    }
    await task();
}

function isPromise(p: any) {
    if (typeof p === 'object' && typeof p.then === 'function') {
        return true;
    }

    return false;
}
