import * as bip39 from "bip39";
import { fromHex, sharedCryptoWorker, toHex } from "ente-base/crypto";

// Mobile client library only supports English.
bip39.setDefaultWordlist("english");

/**
 * Decrypt the provided data that was encrypted with the user's recovery key
 * using the recovery key derived from the provided mnemonic string.
 *
 * @param encryptedData The data to decrypt. The data should've been encrypted
 * using the same recovery key otherwise the decryption would fail.
 *
 * @param decryptionNonce The nonce that was using encryption.
 *
 * @param recoveryKey The BIP-39 mnemonic (24 word) string representing the
 * recovery key. For legacy compatibility, the function also works if provided
 * the hex representation of the recovery key.
 *
 * @returns A base64 string representing the decrypted data.
 */
export const decryptUsingRecoveryKeyMnemonic = async (
    encryptedData: any,
    decryptionNonce: any,
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

    const cryptoWorker = await sharedCryptoWorker();
    return cryptoWorker.decryptB64(
        encryptedData,
        decryptionNonce,
        await fromHex(recoveryKeyHex),
    );
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
