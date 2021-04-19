import constants from 'utils/strings/constants';
import { errorCodes } from './errorUtil';

const TwoSecondInMillSeconds = 2000;

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
    var win = window.open(constants.APP_DOWNLOAD_URL, '_blank');
    win.focus();
}
