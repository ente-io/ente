export enum SESSION_KEYS {
    ENCRYPTION_KEY='encryptionKey',
}

export const setKey = (key: SESSION_KEYS, value: object) => {
    sessionStorage.setItem(key, JSON.stringify(value));
}

export const getKey = (key: SESSION_KEYS) => {
    return JSON.parse(sessionStorage.getItem(key));
}

export const clearKeys = () => {
    sessionStorage.clear();
}
