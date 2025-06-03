import { sharedCryptoWorker } from "ente-base/crypto";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const bip39 = require("bip39");
// mobile client library only supports english.
bip39.setDefaultWordlist("english");

/**
 * Decrypt the provided data that was encrypted with the user's recovery key
 * using the recovery key derived from the provided mnemonic string.
 *
 * @param recoveryKey The BIP-39 mnemonic (24 word) string representing the
 * recovery key. For legacy compatibility, the function also works if provided
 * the hex representation of the recovery key.
 *
 * @param encryptedData The data to decrypt. The data should've been encrypted
 * using the same recovery key otherwise the decryption would fail.
 *
 * @param decryptionNonce The nonce that was using encryption.
 *
 * @returns A base64 string representing the decrypted data.
 */
export const decryptUsingRecoveryKeyMnemonic = async (
    recoveryKey: string,
    encryptedData: any,
    decryptionNonce: any,
) => {
    recoveryKey = recoveryKey
        .trim()
        .split(" ")
        .map((part) => part.trim())
        .filter((part) => !!part)
        .join(" ");

    // Check if user is entering mnemonic recovery key.
    if (recoveryKey.indexOf(" ") > 0) {
        if (recoveryKey.split(" ").length != 24) {
            throw new Error("recovery code should have 24 words");
        }
        recoveryKey = bip39.mnemonicToEntropy(recoveryKey);
    }

    const cryptoWorker = await sharedCryptoWorker();
    return cryptoWorker.decryptB64(
        encryptedData,
        decryptionNonce,
        await cryptoWorker.fromHex(recoveryKey),
    );
};
