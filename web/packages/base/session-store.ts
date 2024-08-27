import { z } from "zod";
import { decryptBox } from "./crypto";
import { toB64 } from "./crypto/libsodium";

/**
 * Return the user's master key (as a base64 string) from session storage.
 *
 * Precondition: The user should be logged in.
 */
export const masterKeyFromSession = async () => {
    // TODO: Same value as the deprecated SESSION_KEYS.ENCRYPTION_KEY.
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) {
        throw new Error(
            "The user's master key was not found in session storage. Likely they are not logged in.",
        );
    }

    const { encryptedData, key, nonce } = EncryptionKeyAttributes.parse(
        JSON.parse(value),
    );

    return decryptBox({ encryptedData, nonce }, key);
};

/**
 * Variant of {@link masterKeyFromSession} that returns the master key as a
 * base64 string.
 */
export const masterKeyB64FromSession = () => masterKeyFromSession().then(toB64);

// TODO: Same as B64EncryptionResult. Revisit.
const EncryptionKeyAttributes = z.object({
    encryptedData: z.string(),
    key: z.string(),
    nonce: z.string(),
});
