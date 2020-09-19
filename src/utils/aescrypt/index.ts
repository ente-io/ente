import { resolve } from 'path';
import { aescrypt } from './aescrypt';

const decrypt = (file: Uint8Array, password: String, binaryResponse: Boolean = false) => {
    return new Promise((resolve, reject) => {
        try {
            aescrypt.decrypt(file, password, !binaryResponse, ({ data, error}) => {
                if (error) {
                    reject(error);
                }
                resolve(data);
            });
        } catch (e) {
            reject(e);
        }
    });
}

export default {
    decrypt,
}
