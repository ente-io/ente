import * as bip39 from "bip39";
import { fromHex, toHex } from "ente-base/crypto";

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
