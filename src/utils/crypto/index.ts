import { KEK } from 'pages/generate';
import { B64EncryptionResult } from 'services/uploadService';
import { KeyAttributes } from 'types';
import * as Comlink from 'comlink';
import { runningInBrowser } from 'utils/common';
import { SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { LS_KEYS, setData } from 'utils/storage/localStorage';

const CryptoWorker: any =
    runningInBrowser() &&
    Comlink.wrap(new Worker('worker/crypto.worker.js', { type: 'module' }));

export async function generateIntermediateKeyAttributes(
    passphrase,
    keyAttributes,
    key
): Promise<KeyAttributes> {
    const cryptoWorker = await new CryptoWorker();
    const intermediateKekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek: KEK = await cryptoWorker.deriveIntermediateKey(
        passphrase,
        intermediateKekSalt
    );
    const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(
        key,
        intermediateKek.key
    );
    return {
        kekSalt: intermediateKekSalt,
        encryptedKey: encryptedKeyAttributes.encryptedData,
        keyDecryptionNonce: encryptedKeyAttributes.nonce,
        publicKey: keyAttributes.publicKey,
        encryptedSecretKey: keyAttributes.encryptedSecretKey,
        secretKeyDecryptionNonce: keyAttributes.secretKeyDecryptionNonce,
        opsLimit: intermediateKek.opsLimit,
        memLimit: intermediateKek.memLimit,
    };
}

export const setSessionKeys = async (key: string) => {
    const cryptoWorker = await new CryptoWorker();
    const sessionKeyAttributes = await cryptoWorker.encryptToB64(key);
    const sessionKey = sessionKeyAttributes.key;
    const sessionNonce = sessionKeyAttributes.nonce;
    const encryptionKey = sessionKeyAttributes.encryptedData;
    setKey(SESSION_KEYS.ENCRYPTION_KEY, { encryptionKey });
    setData(LS_KEYS.SESSION, { sessionKey, sessionNonce });
};

export default CryptoWorker;
