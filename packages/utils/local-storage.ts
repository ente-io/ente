/**
 * Keys corresponding to the items that we save in local storage.
 *
 * The type of each of the these keys is {@link LSKey}.
 *
 * Note: [Local Storage]
 *
 * Data in the local storage is persisted even after the user closes the tab (or
 * the browser itself). This is in contrast with session storage, where the data
 * is cleared when the browser tab is closed.
 *
 * The data in local storage is tied to the Document's origin (scheme + host).
 */
export const lsKeys = ["locale"] as const;

/** The type of {@link lsKeys}. */
export type LSKey = (typeof lsKeys)[number];

/**
 * Read a previously saved string from local storage
 */
export const getLSString = (key: LSKey) => {
    const item = localStorage.getItem(key);
    if (item === null) return undefined;
    return item;
};

/**
 * Save a string in local storage
 */
export const setLSString = (key: LSKey, value: string) => {
    localStorage.setItem(key, value);
};

/**
 * Remove an string from local storage.
 */
export const removeLSString = (key: LSKey) => {
    localStorage.removeItem(key);
};
