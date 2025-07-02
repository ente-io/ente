import * as bip39 from "bip39";
import { getData } from "ente-accounts/services/accounts-db";
import type { KeyAttributes } from "ente-accounts/services/user";
import {
    decryptBox,
    fromHex,
    sharedCryptoWorker,
    toHex,
} from "ente-base/crypto";
import { ensureMasterKeyFromSession } from "ente-base/session";
import { putUserRecoveryKeyAttributes, saveKeyAttributes } from "./user";

// Mobile client library only supports English.
bip39.setDefaultWordlist("english");

/**
 * Convert the provided BIP-39 mnemonic string into its base64 representation.
 *
 * @param recoveryKeyMnemonicOrHex The BIP-39 mnemonic (24 word) string
 * representing the recovery key. For legacy compatibility, the function also
 * works if provided the hex representation of the recovery key.
 *
 * @returns A base64 string representing the underlying bytes of the recovery key.
 */
export const recoveryKeyFromMnemonic = (recoveryKeyMnemonicOrHex: string) => {
    const trimmedInput = recoveryKeyMnemonicOrHex
        .trim()
        .split(" ")
        .map((part) => part.trim())
        .filter((part) => !!part)
        .join(" ");

    let recoveryKeyHex: string;
    // Check if user is entering mnemonic recovery key.
    if (trimmedInput.indexOf(" ") > 0) {
        if (trimmedInput.split(" ").length != 24) {
            throw new Error("recovery code should have 24 words");
        }
        recoveryKeyHex = bip39.mnemonicToEntropy(trimmedInput);
    } else {
        recoveryKeyHex = trimmedInput;
    }

    return fromHex(recoveryKeyHex);
};

/**
 * Convert the provided base64 encoded recovery key into its BIP-39 mnemonic.
 *
 * @param recoveryKey The base64 encoded recovery key to mnemonize.
 *
 * @returns A 24-word mnemonic that serves as the user visible recovery key.
 */
export const recoveryKeyToMnemonic = async (recoveryKey: string) =>
    bip39.entropyToMnemonic(await toHex(recoveryKey));

/**
 * Return the (decrypted) recovery key of the logged in user, reading it from
 * local storage.
 *
 * As a fallback for old accounts that generated recovery keys on first view,
 * this function will also generate a new recovery key if needed.
 *
 * @returns The user's base64 encoded recovery key.
 */
export const getUserRecoveryKey = async () => {
    const masterKey = await ensureMasterKeyFromSession();

    const keyAttributes: KeyAttributes = getData("keyAttributes");
    const { recoveryKeyEncryptedWithMasterKey, recoveryKeyDecryptionNonce } =
        keyAttributes;

    if (recoveryKeyEncryptedWithMasterKey && recoveryKeyDecryptionNonce) {
        return decryptBox(
            {
                encryptedData: recoveryKeyEncryptedWithMasterKey,
                nonce: recoveryKeyDecryptionNonce,
            },
            masterKey,
        );
    } else {
        return createNewRecoveryKey(masterKey);
    }
};

/**
 * Generate a new recovery key, tell remote about it, update our local state,
 * and then return it.
 *
 * This function is meant only for (very!) old accounts for whom the app did not
 * generate recovery keys on sign up but instead generated them on first view.
 *
 * @returns a new base64 encoded recovery key.
 */
const createNewRecoveryKey = async (masterKey: string) => {
    const existingAttributes = getData("keyAttributes");

    const cryptoWorker = await sharedCryptoWorker();
    const recoveryKey = await cryptoWorker.generateKey();
    const encryptedMasterKey = await cryptoWorker.encryptBox(
        masterKey,
        recoveryKey,
    );
    const encryptedRecoveryKey = await cryptoWorker.encryptBox(
        recoveryKey,
        masterKey,
    );

    const recoveryKeyAttributes = {
        masterKeyEncryptedWithRecoveryKey: encryptedMasterKey.encryptedData,
        masterKeyDecryptionNonce: encryptedMasterKey.nonce,
        recoveryKeyEncryptedWithMasterKey: encryptedRecoveryKey.encryptedData,
        recoveryKeyDecryptionNonce: encryptedRecoveryKey.nonce,
    };

    await putUserRecoveryKeyAttributes(recoveryKeyAttributes);

    saveKeyAttributes({ ...existingAttributes, ...recoveryKeyAttributes });

    return recoveryKey;
};
