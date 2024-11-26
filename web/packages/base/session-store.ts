import { z } from "zod";
import { decryptBox } from "./crypto";
import { toB64 } from "./crypto/libsodium";

/**
 * Return the user's master key from session storage.
 *
 * Precondition: The user should be logged in.
 */
export const masterKeyFromSession = async () => {
    const key = await masterKeyFromSessionIfLoggedIn();
    if (key) {
        return key;
    } else {
        throw new Error(
            "The user's master key was not found in session storage. Likely they are not logged in.",
        );
    }
};

/**
 * Return the user's master key from session storage if they are logged in,
 * otherwise return `undefined`.
 */
export const masterKeyFromSessionIfLoggedIn = async () => {
    // TODO: Same value as the deprecated SESSION_KEYS.ENCRYPTION_KEY.
    const value = sessionStorage.getItem("encryptionKey");
    if (!value) return undefined;

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
