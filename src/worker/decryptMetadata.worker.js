import { base64ToUint8 } from "utils/crypto/common";
import sodium from 'libsodium-wrappers';

function decryptMetadata(event) {
    const main = async () => {
        const data = event.data.data;
        await sodium.ready;
        const key = sodium.crypto_secretbox_open_easy(
            base64ToUint8(data.metadata.decryptionParams.encryptedKey),
            base64ToUint8(data.metadata.decryptionParams.keyDecryptionNonce),
            base64ToUint8(event.data.key));
        const metadata = sodium.crypto_secretbox_open_easy(
            base64ToUint8(data.metadata.encryptedData),
            base64ToUint8(data.metadata.decryptionParams.nonce),
            key);
        self.postMessage({
            ...data,
            metadata: JSON.parse(new TextDecoder().decode(metadata))
        });
    }
    main();
}

self.addEventListener('message', decryptMetadata);
