export type SessionKey = "encryptionKey" | "keyEncryptionKey";

export const setKey = (key: SessionKey, value: object) =>
    sessionStorage.setItem(key, JSON.stringify(value));

export const getKey = (key: SessionKey) => {
    const value = sessionStorage.getItem(key);
    return value && JSON.parse(value);
};

export const removeKey = (key: SessionKey) => sessionStorage.removeItem(key);

export const clearKeys = () => sessionStorage.clear();
