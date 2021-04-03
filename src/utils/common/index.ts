import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { errorCodes } from './errorUtil';

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    } else {
        throw new Error(errorCodes.ERR_NO_INTERNET_CONNECTION);
    }
}

export function getFileExtension(fileName): string {
    return fileName.substr(fileName.lastIndexOf('.') + 1).toLowerCase();
}

export function runningInBrowser() {
    return typeof window !== 'undefined';
}

export const isFirstLogin = () =>
    getData(LS_KEYS.IS_FIRST_LOGIN)?.status ?? false;

export function setIsFirstLogin(status) {
    setData(LS_KEYS.IS_FIRST_LOGIN, { status });
}
