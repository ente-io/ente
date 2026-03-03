import {
    decryptBox,
    decryptMetadataJSON,
    deriveInteractiveKey,
    deriveKey,
    encryptBox,
    encryptMetadataJSON,
    generateKey,
} from "ente-base/crypto";
import { newID } from "ente-base/id";
import type { PastePayload } from "services/paste";
import { FRAGMENT_SECRET_LENGTH, FRAGMENT_SECRET_PATTERN } from "../constants";

export const createFragmentSecret = () =>
    newID("").slice(0, FRAGMENT_SECRET_LENGTH);

export const encryptPasteForCreate = async (text: string) => {
    const key = await generateKey();
    const fragmentSecret = createFragmentSecret();

    const encrypted = await encryptMetadataJSON({ text }, key);
    const keyEncryptionKey = await deriveInteractiveKey(fragmentSecret);
    const encryptedPasteKey = await encryptBox(key, keyEncryptionKey.key);

    return {
        fragmentSecret,
        payload: {
            encryptedData: encrypted.encryptedData,
            decryptionHeader: encrypted.decryptionHeader,
            encryptedPasteKey: encryptedPasteKey.encryptedData,
            encryptedPasteKeyNonce: encryptedPasteKey.nonce,
            kdfNonce: keyEncryptionKey.salt,
            kdfMemLimit: keyEncryptionKey.memLimit,
            kdfOpsLimit: keyEncryptionKey.opsLimit,
        } satisfies PastePayload,
    };
};

const resolvePasteKey = async (
    fragmentSecret: string,
    payload: PastePayload,
) => {
    if (!FRAGMENT_SECRET_PATTERN.test(fragmentSecret)) {
        throw new Error("Invalid key in URL");
    }

    const keyEncryptionKey = await deriveKey(
        fragmentSecret,
        payload.kdfNonce,
        payload.kdfOpsLimit,
        payload.kdfMemLimit,
    );

    return await decryptBox(
        {
            encryptedData: payload.encryptedPasteKey,
            nonce: payload.encryptedPasteKeyNonce,
        },
        keyEncryptionKey,
    );
};

export const decryptConsumedPaste = async (
    fragmentSecret: string,
    payload: PastePayload,
) => {
    const key = await resolvePasteKey(fragmentSecret, payload);
    const decrypted = (await decryptMetadataJSON(
        {
            encryptedData: payload.encryptedData,
            decryptionHeader: payload.decryptionHeader,
        },
        key,
    )) as { text?: string };

    if (typeof decrypted.text !== "string") {
        throw new Error("Unable to decrypt paste");
    }

    return decrypted.text;
};
