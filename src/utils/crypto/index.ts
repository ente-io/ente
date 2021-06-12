import { KEK } from 'pages/generate';
import { B64EncryptionResult } from 'services/uploadService';
import { KeyAttributes } from 'types';
import * as Comlink from 'comlink';
import { runningInBrowser } from 'utils/common';
import { SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getActualKey, getToken } from 'utils/common/key';
import { setRecoveryKey } from 'services/userService';

export interface ComlinkWorker {
    comlink: any;
    worker: Worker;
}

export const getDedicatedCryptoWorker = (): ComlinkWorker => {
    if (runningInBrowser()) {
        const worker = new Worker('worker/crypto.worker.js', {
            type: 'module',
        });
        const comlink = Comlink.wrap(worker);
        return { comlink, worker };
    }
};
const CryptoWorker: any = getDedicatedCryptoWorker()?.comlink;

export async function generateKeyAttributes(
    passphrase: string,
): Promise<{ keyAttributes: KeyAttributes; masterKey: string }> {
    const cryptoWorker = await new CryptoWorker();
    const masterKey: string = await cryptoWorker.generateEncryptionKey();
    const recoveryKey: string = await cryptoWorker.generateEncryptionKey();
    const kekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
    const kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);

    const masterKeyEncryptedWithKek: B64EncryptionResult = await cryptoWorker.encryptToB64(masterKey, kek.key);
    const masterKeyEncryptedWithRecoveryKey: B64EncryptionResult = await cryptoWorker.encryptToB64(masterKey, recoveryKey);
    const recoveryKeyEncryptedWithMasterKey: B64EncryptionResult = await cryptoWorker.encryptToB64(recoveryKey, masterKey);

    const keyPair = await cryptoWorker.generateKeyPair();
    const encryptedKeyPairAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(keyPair.privateKey, masterKey);

    const keyAttributes: KeyAttributes = {
        kekSalt,
        encryptedKey: masterKeyEncryptedWithKek.encryptedData,
        keyDecryptionNonce: masterKeyEncryptedWithKek.nonce,
        publicKey: keyPair.publicKey,
        encryptedSecretKey: encryptedKeyPairAttributes.encryptedData,
        secretKeyDecryptionNonce: encryptedKeyPairAttributes.nonce,
        opsLimit: kek.opsLimit,
        memLimit: kek.memLimit,
        masterKeyEncryptedWithRecoveryKey:
            masterKeyEncryptedWithRecoveryKey.encryptedData,
        masterKeyDecryptionNonce: masterKeyEncryptedWithRecoveryKey.nonce,
        recoveryKeyEncryptedWithMasterKey:
            recoveryKeyEncryptedWithMasterKey.encryptedData,
        recoveryKeyDecryptionNonce: recoveryKeyEncryptedWithMasterKey.nonce,
    };

    return { keyAttributes, masterKey };
}

export async function generateAndSaveIntermediateKeyAttributes(
    passphrase,
    existingKeyAttributes,
    key,
): Promise<KeyAttributes> {
    const cryptoWorker = await new CryptoWorker();
    const intermediateKekSalt: string = await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek: KEK = await cryptoWorker.deriveIntermediateKey(
        passphrase,
        intermediateKekSalt,
    );
    const encryptedKeyAttributes: B64EncryptionResult = await cryptoWorker.encryptToB64(key, intermediateKek.key);

    const intermediateKeyAttributes = Object.assign(existingKeyAttributes, {
        kekSalt: intermediateKekSalt,
        encryptedKey: encryptedKeyAttributes.encryptedData,
        keyDecryptionNonce: encryptedKeyAttributes.nonce,
        opsLimit: intermediateKek.opsLimit,
        memLimit: intermediateKek.memLimit,
    });
    setData(LS_KEYS.KEY_ATTRIBUTES, intermediateKeyAttributes);
    return intermediateKeyAttributes;
}

export const setSessionKeys = async (key: string) => {
    const cryptoWorker = await new CryptoWorker();
    const sessionKeyAttributes = await cryptoWorker.encryptToB64(key);
    setKey(SESSION_KEYS.ENCRYPTION_KEY, sessionKeyAttributes);
};

export const getRecoveryKey = async () => {
    let recoveryKey = null;
    try {
        const cryptoWorker = await new CryptoWorker();

        const keyAttributes: KeyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
        const {
            recoveryKeyEncryptedWithMasterKey,
            recoveryKeyDecryptionNonce,
        } = keyAttributes;
        const masterKey = await getActualKey();
        if (recoveryKeyEncryptedWithMasterKey) {
            recoveryKey = await cryptoWorker.decryptB64(
                recoveryKeyEncryptedWithMasterKey,
                recoveryKeyDecryptionNonce,
                masterKey,
            );
        } else {
            recoveryKey = await createNewRecoveryKey();
        }
        recoveryKey = await cryptoWorker.toHex(recoveryKey);
        return recoveryKey;
    } catch (e) {
        console.error('getRecoveryKey failed', e.message);
    }
};

async function createNewRecoveryKey() {
    const masterKey = await getActualKey();
    const existingAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);

    const cryptoWorker = await new CryptoWorker();

    const recoveryKey = await cryptoWorker.generateEncryptionKey();
    const encryptedMasterKey: B64EncryptionResult = await cryptoWorker.encryptToB64(masterKey, recoveryKey);
    const encryptedRecoveryKey: B64EncryptionResult = await cryptoWorker.encryptToB64(recoveryKey, masterKey);
    const recoveryKeyAttributes = {
        masterKeyEncryptedWithRecoveryKey: encryptedMasterKey.encryptedData,
        masterKeyDecryptionNonce: encryptedMasterKey.nonce,
        recoveryKeyEncryptedWithMasterKey: encryptedRecoveryKey.encryptedData,
        recoveryKeyDecryptionNonce: encryptedRecoveryKey.nonce,
    };
    await setRecoveryKey(getToken(), recoveryKeyAttributes);

    const updatedKeyAttributes = Object.assign(
        existingAttributes,
        recoveryKeyAttributes,
    );
    setData(LS_KEYS.KEY_ATTRIBUTES, updatedKeyAttributes);

    return recoveryKey;
}
export default CryptoWorker;
