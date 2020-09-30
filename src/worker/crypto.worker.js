import * as Comlink from 'comlink';
import { base64ToUint8 } from "utils/crypto/common";
import sodium from 'libsodium-wrappers';

class Crypto {
    async decryptMetadata(event) {
        const { data } = event;
        const key = await this.decrypt(
            base64ToUint8(data.metadata.decryptionParams.encryptedKey),
            base64ToUint8(data.metadata.decryptionParams.keyDecryptionNonce),
            base64ToUint8(event.key));
        const metadata = await this.decrypt(
            base64ToUint8(data.metadata.encryptedData),
            base64ToUint8(data.metadata.decryptionParams.nonce),
            key);
        return {
            ...data,
            metadata: JSON.parse(new TextDecoder().decode(metadata))
        };
    }

    async decryptThumbnail(event) {
        const { data } = event;
        const key = await this.decrypt(
            base64ToUint8(data.thumbnail.decryptionParams.encryptedKey),
            base64ToUint8(data.thumbnail.decryptionParams.keyDecryptionNonce),
            base64ToUint8(event.key));
        const thumbnail = await this.decrypt(
            new Uint8Array(data.file),
            base64ToUint8(data.thumbnail.decryptionParams.nonce),
            key);
        return {
            id: data.id,
            data: thumbnail,
        };
    }

    async decrypt(data, nonce, key) {
        await sodium.ready;
        return sodium.crypto_secretbox_open_easy(data, nonce, key);
    }
}

Comlink.expose(Crypto);
