import isElectron from 'is-electron';

export function runningInBrowser() {
    return typeof window !== 'undefined';
}

export function runningInWorker() {
    return typeof importScripts === 'function';
}

export function runningInElectron() {
    return isElectron();
}
