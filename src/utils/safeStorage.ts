import { safeStorage } from 'electron';
import { safeStorageStore } from '../services/store';

export function setEncryptionKey(encryptionKey: string) {
    const buffer = safeStorage.encryptString(encryptionKey);
    safeStorageStore.set('encryptionKey', buffer.toString('base64'));
}

export function getEncryptionKey() {
    const bufferString = safeStorageStore.get('encryptionKey');
    return safeStorage.decryptString(Buffer.from(bufferString, 'base64'));
}
