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

export async function generateAndSaveIntermediateKeyAttributes(
    passphrase,
    keyAttributes,
    key
) {
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

    const updatedKeyAttributes = {
        kekSalt: intermediateKekSalt,
        encryptedKey: encryptedKeyAttributes.encryptedData,
        keyDecryptionNonce: encryptedKeyAttributes.nonce,
        publicKey: keyAttributes.publicKey,
        encryptedSecretKey: keyAttributes.encryptedSecretKey,
        secretKeyDecryptionNonce: keyAttributes.secretKeyDecryptionNonce,
        opsLimit: intermediateKek.opsLimit,
        memLimit: intermediateKek.memLimit,
    };
    setData(LS_KEYS.KEY_ATTRIBUTES, updatedKeyAttributes);
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

export const getRecoveryKey = async () => {
    return 'dsadsadsadasdq3ds7a6d5sa76ds7ad5s7a6d57sa6d57s6ad57sdsadsadsadasdq3ds7a6d5sa76ds7ad5s7a6d57sa6d57s6ad57sa6d5sa76das7d45dsadsadsadasdq3ds7a6d5sa76ds7ad5s7a6d57sa6d57s6ad57sa6d5sa76das7d45a6d5sa76das7d45';
};

export default CryptoWorker;
