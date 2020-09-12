import { base64ToUint8, binToBase64 } from './common';

/**
 * Takes base64 encoded binary data, key and iv and returns
 * base64 encoded encrypted binary message.
 * @param data
 * @param key
 * @param iv
 */
export async function encrypt(data: string, key: string, iv: string) {
    const cryptoKey = await crypto.subtle.importKey(
        'raw', base64ToUint8(key), { name: 'AES-CBC' },
        false, ['encrypt', 'decrypt']
    );

    const result = await window.crypto.subtle.encrypt(
        {
            name: "AES-CBC",
            iv: base64ToUint8(iv),
        },
        cryptoKey,
        base64ToUint8(data),
    );

    return binToBase64(result);
}

/**
 * Takes base64 encoded binary data, key and iv and returns
 * base64 encoded decrypted binary message.
 * @param data
 * @param key
 * @param iv
 */
export async function decrypt(data: string, key: string, iv: string) {
    const cryptoKey = await crypto.subtle.importKey(
        'raw', base64ToUint8(key), { name: 'AES-CBC' },
        false, ['encrypt', 'decrypt']
    );

    const result = await window.crypto.subtle.decrypt(
        {
            name: "AES-CBC",
            iv: base64ToUint8(iv),
        },
        cryptoKey,
        base64ToUint8(data),
    );

    return binToBase64(result);
}