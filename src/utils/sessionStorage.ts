export enum SESSION_KEYS {
    USER='user',
    SESSION='session',
    KEY_ATTRIBUTES='keyAttributes',
}

export const setData = (key: SESSION_KEYS, value: object) => {
    sessionStorage.setItem(key, JSON.stringify(value));
}

export const getData = (key: SESSION_KEYS) => {
    return JSON.parse(sessionStorage.getItem(key));
}

export const clearData = () => {
    sessionStorage.clear();
}
