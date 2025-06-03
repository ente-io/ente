import * as bip39 from "bip39";
import {
    decryptBoxB64,
    fromHex,
    sharedCryptoWorker,
    toHex,
} from "ente-base/crypto";
import { masterKeyFromSession } from "ente-base/session";
import { getData, setData } from "ente-shared/storage/localStorage";
import type { KeyAttributes } from "ente-shared/user/types";
import { putUserRecoveryKeyAttributes } from "./user";

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
export const recoveryKeyB64FromMnemonic = (
    recoveryKeyMnemonicOrHex: string,
) => {
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
 * @param recoveryKeyB64 The base64 encoded recovery key to mnemonize.
 *
 * @returns A 24-word mnemonic that serves as the user visible recovery key.
 */
export const recoveryKeyB64ToMnemonic = async (recoveryKeyB64: string) =>
    bip39.entropyToMnemonic(await toHex(recoveryKeyB64));

/**
 * Return the (decrypted) recovery key of the logged in user.
 *
 * @returns The user's base64 encoded recovery key.
 */
export const getUserRecoveryKeyB64 = async () => {
    const masterKey = await masterKeyFromSession();

    const keyAttributes: KeyAttributes = getData("keyAttributes");
    const { recoveryKeyEncryptedWithMasterKey, recoveryKeyDecryptionNonce } =
        keyAttributes;

    if (recoveryKeyEncryptedWithMasterKey && recoveryKeyDecryptionNonce) {
        return decryptBoxB64(
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
 * This function will be used only for legacy users for whom we did not generate
 * recovery keys during sign up.
 *
 * @returns a new base64 encoded recovery key.
 */
const createNewRecoveryKey = async (masterKey: Uint8Array) => {
    const existingAttributes = getData("keyAttributes");

    const cryptoWorker = await sharedCryptoWorker();
    const recoveryKey = await cryptoWorker.generateKey();
    const encryptedMasterKey = await cryptoWorker.encryptBoxB64(
        masterKey,
        recoveryKey,
    );
    const encryptedRecoveryKey = await cryptoWorker.encryptBoxB64(
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

    setData("keyAttributes", {
        ...existingAttributes,
        ...recoveryKeyAttributes,
    });

    return recoveryKey;
};
