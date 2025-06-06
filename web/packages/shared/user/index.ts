import { sharedCryptoWorker } from "ente-base/crypto";
import type { B64EncryptionResult } from "ente-base/crypto/libsodium";
import { getKey } from "ente-shared/storage/sessionStorage";

/**
 * Deprecated, use {@link ensureMasterKeyFromSession} instead.
 */
export const getActualKey = async () => {
    const encryptionKeyAttributes: B64EncryptionResult =
        getKey("encryptionKey");

    const cryptoWorker = await sharedCryptoWorker();
    const key = await cryptoWorker.decryptBox(
        {
            encryptedData: encryptionKeyAttributes.encryptedData,
            nonce: encryptionKeyAttributes.nonce,
        },
        encryptionKeyAttributes.key,
    );
    return key;
};
