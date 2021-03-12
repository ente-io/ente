export enum LS_KEYS {
    USER = 'user',
    SESSION = 'session',
    KEY_ATTRIBUTES = 'keyAttributes',
    SUBSCRIPTION = 'subscription',
}

export const setData = (key: LS_KEYS, value: object) => {
    if (typeof localStorage === 'undefined') {
        return null;
    }
    localStorage.setItem(key, JSON.stringify(value));
};

export const getData = (key: LS_KEYS) => {
    try {
        if (
            typeof localStorage === 'undefined' ||
            typeof key === 'undefined' ||
            typeof localStorage.getItem(key) === 'undefined'
        ) {
            return null;
        }
        return JSON.parse(localStorage.getItem(key));
    } catch (e) {
        console.log('Failed to Parse JSON');
    }
};

export const clearData = () => {
    if (typeof localStorage === 'undefined') {
        return null;
    }
    localStorage.clear();
};
