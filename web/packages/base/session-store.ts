import { sharedCryptoWorker } from "@/base/crypto";
import { z } from "zod";

/**
 * Return the user's encryption key from session storage.
 *
 * Precondition: The user should be logged in.
 */
export const userEncryptionKey = async () => {
    // TODO: Same value as the deprecated SESSION_KEYS.ENCRYPTION_KEY.
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) {
        throw new Error(
            "The user's encryption key was not found in session storage. Likely they are not logged in.",
        );
    }

    const { encryptedData, key, nonce } = EncryptionKeyAttributes.parse(
        JSON.parse(value),
    );

    const cryptoWorker = await sharedCryptoWorker();
    return cryptoWorker.decryptB64(encryptedData, nonce, key);
};

// TODO: Same as B64EncryptionResult. Revisit.
const EncryptionKeyAttributes = z.object({
    encryptedData: z.string(),
    key: z.string(),
    nonce: z.string(),
});
