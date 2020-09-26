import { base64ToUint8 } from "utils/crypto/common";
import sodium from 'libsodium-wrappers';

function decryptThumbnail(event) {
    const main = async () => {
        const data = event.data.data;
        await sodium.ready;
        const key = sodium.crypto_secretbox_open_easy(
            base64ToUint8(data.thumbnail.decryptionParams.encryptedKey),
            base64ToUint8(data.thumbnail.decryptionParams.keyDecryptionNonce),
            base64ToUint8(event.data.key));
        const thumbnail = sodium.crypto_secretbox_open_easy(
            new Uint8Array(data.file),
            base64ToUint8(data.thumbnail.decryptionParams.nonce),
            key);
        self.postMessage({
            id: data.id,
            data: thumbnail,
        });
    }
    main();
}

self.addEventListener('message', decryptThumbnail);
