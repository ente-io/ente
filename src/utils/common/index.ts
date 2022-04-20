import constants from 'utils/strings/constants';
import { CustomError } from 'utils/error';

export const DESKTOP_APP_DOWNLOAD_URL =
    'https://github.com/ente-io/bhari-frame/releases/latest';

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
    const win = window.open(DESKTOP_APP_DOWNLOAD_URL, '_blank');
    win.focus();
}

export function reverseString(title: string) {
    return title
        ?.split(' ')
        .reduce((reversedString, currWord) => `${currWord} ${reversedString}`);
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
        requestWithTimeOutCancellation,
        rejectOnTimeout,
    ]);
};
