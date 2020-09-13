export enum LS_KEYS {
    USER='user',
    SESSION='session',
    KEY_ATTRIBUTES='keyAttributes',
}

export const setData = (key: LS_KEYS, value: object) => {
    localStorage.setItem(key, JSON.stringify(value));
}

export const getData = (key: LS_KEYS) => {
    return JSON.parse(localStorage.getItem(key));
}

export const clearData = () => {
    localStorage.clear();
}
