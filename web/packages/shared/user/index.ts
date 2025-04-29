import { sharedCryptoWorker } from "ente-base/crypto";
import type { B64EncryptionResult } from "ente-base/crypto/libsodium";
import { CustomError } from "ente-shared/error";
import { getKey } from "ente-shared/storage/sessionStorage";

export const getActualKey = async () => {
    try {
        const encryptionKeyAttributes: B64EncryptionResult =
            getKey("encryptionKey");

        const cryptoWorker = await sharedCryptoWorker();
        const key = await cryptoWorker.decryptB64(
            encryptionKeyAttributes.encryptedData,
            encryptionKeyAttributes.nonce,
            encryptionKeyAttributes.key,
        );
        return key;
    } catch {
        throw new Error(CustomError.KEY_MISSING);
    }
};
