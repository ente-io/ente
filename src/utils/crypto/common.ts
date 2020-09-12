/**
 * Converts base64 encoded string to Uint8 Array.
 * @param str
 */
export const base64ToUint8 = (str: string) => Uint8Array.from(atob(str), c => c.charCodeAt(0));

/**
 * Converts string to Uint8 Array.
 * @param str
 */
export const strToUint8 = (str: string) => Uint8Array.from(str, c => c.charCodeAt(0));

/**
 * Converts binary data to base64 encoded string.
 * @param bin
 */
export const binToBase64 = (bin: Uint8Array | ArrayBuffer) => btoa(
    String.fromCharCode(...new Uint8Array(bin)));

/**
 * Generates base64 encoded string of random bytes of given length.
 * @param length 
 */
export const secureRandomString = (length: number) => binToBase64(
    crypto.getRandomValues(new Uint8Array(length)));