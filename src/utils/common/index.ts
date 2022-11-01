import constants from 'utils/strings/constants';
import { CustomError } from 'utils/error';

const APP_DOWNLOAD_URL = 'https://ente.io/download/desktop';

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    }
    throw new Error(constants.NO_INTERNET_CONNECTION);
}

export function runningInBrowser() {
    return typeof window !== 'undefined';
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
