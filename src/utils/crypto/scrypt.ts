import * as scrypt from 'scrypt-js';
import { binToBase64 } from './common';

export const hash = async (passphrase: Uint8Array, salt: Uint8Array) => {
    const result = await scrypt.scrypt(passphrase, salt, 16384, 16, 1, 32);
    return binToBase64(result);
}
