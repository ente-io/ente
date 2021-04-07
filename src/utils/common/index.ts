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

export function downloadAsFile(filename: string, content: string) {
    const file = new Blob([content], {
        type: 'text/plain',
    });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(file);
    a.download = filename;

    a.style.display = 'none';
    document.body.appendChild(a);

    a.click();

    a.remove();
}
