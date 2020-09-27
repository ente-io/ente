import * as Comlink from 'comlink';
import { base64ToUint8 } from "utils/crypto/common";
import sodium from 'libsodium-wrappers';

async function decryptThumbnail(event) {
    const { data } = event;
    await sodium.ready;
    const key = sodium.crypto_secretbox_open_easy(
        base64ToUint8(data.thumbnail.decryptionParams.encryptedKey),
        base64ToUint8(data.thumbnail.decryptionParams.keyDecryptionNonce),
        base64ToUint8(event.key));
    const thumbnail = sodium.crypto_secretbox_open_easy(
        new Uint8Array(data.file),
        base64ToUint8(data.thumbnail.decryptionParams.nonce),
        key);
    return {
        id: data.id,
        data: thumbnail,
    };
}

Comlink.expose(decryptThumbnail, self);
