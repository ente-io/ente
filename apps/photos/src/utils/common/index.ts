import { CustomError } from '@ente/shared/error';
import isElectron from 'is-electron';
import { APP_DOWNLOAD_URL } from '@ente/shared/constants/urls';

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    }
    throw new Error(CustomError.NO_INTERNET_CONNECTION);
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

export function downloadApp() {
    openLink(APP_DOWNLOAD_URL, true);
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
export const promiseWithTimeout = async <T>(
    request: Promise<T>,
    timeout: number
): Promise<T> => {
    const timeoutRef = { current: null };
    const rejectOnTimeout = new Promise<null>((_, reject) => {
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

export function isClipboardItemPresent() {
    return typeof ClipboardItem !== 'undefined';
}

export function batch<T>(arr: T[], batchSize: number): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < arr.length; i += batchSize) {
        batches.push(arr.slice(i, i + batchSize));
    }
    return batches;
}

export const mergeMaps = <K, V>(map1: Map<K, V>, map2: Map<K, V>) => {
    const mergedMap = new Map<K, V>(map1);
    map2.forEach((value, key) => {
        mergedMap.set(key, value);
    });
    return mergedMap;
};
