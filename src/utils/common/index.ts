import { errorCodes } from './errorUtil';

const TwoSecondInMillSeconds = 2000;
const DESKTOP_APP_DOWNLOAD_URL =
    'https://github.com/ente-io/bhari-frame/releases/';

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    } else {
        throw new Error(errorCodes.ERR_NO_INTERNET_CONNECTION);
    }
}

export function runningInBrowser() {
    return typeof window !== 'undefined';
}

export async function WaitFor2Seconds() {
    await new Promise((resolve) => {
        setTimeout(() => resolve(null), TwoSecondInMillSeconds);
    });
}
export function downloadApp() {
    var win = window.open(DESKTOP_APP_DOWNLOAD_URL, '_blank');
    win.focus();
}
export function reverseString(title: string) {
    return title
        ?.split(' ')
        .reduce((reversedString, currWord) => `${currWord} ${reversedString}`);
}

export function formatDate(date: Date) {
    return new Intl.DateTimeFormat('en-IN', {
        month: 'long',
        day: 'numeric',
    }).format(date);
}
