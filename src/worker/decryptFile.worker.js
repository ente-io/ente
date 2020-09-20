import { decrypt } from "utils/crypto/aes";
import { strToUint8 } from "utils/crypto/common";
import aescrypt from 'utils/aescrypt';

function decryptFile(event) {
    const main = async () => {
        const data = event.data.data;
        const key = event.data.key;
        const password = await decrypt(data.encryptedPassword, key, data.encryptedPasswordIV);
        const file = await aescrypt.decrypt(data.file, atob(password), true);
        self.postMessage({
            id: data.id,
            file: file,
        });
    }
    main();
}

self.addEventListener('message', decryptFile);
