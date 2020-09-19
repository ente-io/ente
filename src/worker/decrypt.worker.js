import { decrypt } from "utils/crypto/aes";
import { base64ToUint8 } from "utils/crypto/common";
import aescrypt from 'utils/aescrypt';

function decryptFile(event) {
    const main = async () => {
        const data = event.data.data;
        const key = event.data.key;
        const password = await decrypt(data.encryptedPassword, key, data.encryptedPasswordIV);
        const metadata = await aescrypt.decrypt(base64ToUint8(data.encryptedMetadata), atob(password));
        self.postMessage({
            id: data.id,
            ownerId: data.ownerId,
            updationTime: data.updationTime,
            password,
            metadata: JSON.parse(metadata),
        });
    }
    main();
}

self.addEventListener('message', decryptFile);
