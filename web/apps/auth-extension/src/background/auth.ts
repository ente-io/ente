/**
 * Authentication management for the extension.
 */
import { deriveKey, decryptBoxBytes, fromB64, toB64 } from "@shared/crypto";
import type { AuthState, KeyAttributes } from "@shared/types";
import { authStorage, clearAllStorage, codesStorage } from "./storage";

/**
 * Get the current authentication state.
 */
export const getAuthState = async (): Promise<AuthState> => {
    const token = await authStorage.getToken();
    const masterKey = await authStorage.getMasterKey();
    const email = await authStorage.getEmail();

    return {
        isLoggedIn: !!token,
        isUnlocked: !!masterKey,
        email,
    };
};

/**
 * Store login credentials and key attributes.
 */
export const login = async (
    token: string,
    keyAttributes: KeyAttributes,
    email: string
): Promise<void> => {
    await authStorage.setToken(token);
    await authStorage.setKeyAttributes(keyAttributes);
    await authStorage.setEmail(email);
};

/**
 * Unlock the vault by deriving the master key from the password.
 */
export const unlock = async (password: string): Promise<boolean> => {
    const keyAttributes = await authStorage.getKeyAttributes();
    if (!keyAttributes) {
        throw new Error("No key attributes found. Please log in first.");
    }

    try {
        // Derive KEK (Key Encryption Key) from password
        const kek = await deriveKey(
            password,
            keyAttributes.kekSalt,
            keyAttributes.opsLimit,
            keyAttributes.memLimit
        );

        // Decrypt the master key using KEK
        const masterKeyBytes = await decryptBoxBytes(
            {
                encryptedData: keyAttributes.encryptedKey,
                nonce: keyAttributes.keyDecryptionNonce,
            },
            kek
        );

        const masterKey = await toB64(masterKeyBytes);

        // Verify by checking against the hash (optional, depends on backend)
        // For now, we assume successful decryption means correct password

        await authStorage.setMasterKey(masterKey);
        return true;
    } catch (e) {
        console.error("Failed to unlock:", e);
        return false;
    }
};

/**
 * Lock the vault (clear session data but keep credentials).
 */
export const lock = async (): Promise<void> => {
    await authStorage.clearMasterKey();
    await codesStorage.clearCodes();
};

/**
 * Log out completely (clear all data).
 */
export const logout = async (): Promise<void> => {
    await clearAllStorage();
};

/**
 * Check if the user is logged in.
 */
export const isLoggedIn = async (): Promise<boolean> => {
    const token = await authStorage.getToken();
    return !!token;
};

/**
 * Check if the vault is unlocked.
 */
export const isUnlocked = async (): Promise<boolean> => {
    const masterKey = await authStorage.getMasterKey();
    return !!masterKey;
};

/**
 * Get the auth token.
 */
export const getToken = async (): Promise<string | undefined> => {
    return authStorage.getToken();
};

/**
 * Get the master key.
 */
export const getMasterKey = async (): Promise<string | undefined> => {
    return authStorage.getMasterKey();
};
