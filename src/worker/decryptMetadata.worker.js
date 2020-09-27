import * as Comlink from 'comlink';
import { base64ToUint8 } from "utils/crypto/common";
import sodium from 'libsodium-wrappers';

async function decryptMetadata(event) {
    console.log(event);
    const { data } = event;
    await sodium.ready;
    const key = sodium.crypto_secretbox_open_easy(
        base64ToUint8(data.metadata.decryptionParams.encryptedKey),
        base64ToUint8(data.metadata.decryptionParams.keyDecryptionNonce),
        base64ToUint8(event.key));
    const metadata = sodium.crypto_secretbox_open_easy(
        base64ToUint8(data.metadata.encryptedData),
        base64ToUint8(data.metadata.decryptionParams.nonce),
        key);
    return {
        ...data,
        metadata: JSON.parse(new TextDecoder().decode(metadata))
    };
}

Comlink.expose(decryptMetadata, self);
