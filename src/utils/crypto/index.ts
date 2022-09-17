import { KEK, KeyAttributes } from 'types/user';
import { SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getActualKey, getToken } from 'utils/common/key';
import { setRecoveryKey } from 'services/userService';
import { logError } from 'utils/sentry';
import isElectron from 'is-electron';
import safeStorageService from 'services/electron/safeStorage';
import { CryptoWorker } from 'utils/comlink';

export interface B64EncryptionResult {
    encryptedData: string;
    key: string;
    nonce: string;
}

export async function generateKeyAttributes(
    passphrase: string
): Promise<{ keyAttributes: KeyAttributes; masterKey: string }> {
    const cryptoWorker = await new CryptoWorker();
    const masterKey = await cryptoWorker.generateEncryptionKey();
    const recoveryKey = await cryptoWorker.generateEncryptionKey();
    const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
    const kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);

    const masterKeyEncryptedWithKek = await cryptoWorker.encryptToB64(
        masterKey,
        kek.key
    );
    const masterKeyEncryptedWithRecoveryKey = await cryptoWorker.encryptToB64(
        masterKey,
        recoveryKey
    );
    const recoveryKeyEncryptedWithMasterKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey
    );

    const keyPair = await cryptoWorker.generateKeyPair();
    const encryptedKeyPairAttributes = await cryptoWorker.encryptToB64(
        keyPair.privateKey,
        masterKey
    );

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
    passphrase: string,
    existingKeyAttributes: KeyAttributes,
    key: string
): Promise<KeyAttributes> {
    const cryptoWorker = await new CryptoWorker();
    const intermediateKekSalt: string =
        await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek: KEK = await cryptoWorker.deriveInteractiveKey(
        passphrase,
        intermediateKekSalt
    );
    const encryptedKeyAttributes = await cryptoWorker.encryptToB64(
        key,
        intermediateKek.key
    );

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

export const saveKeyInSessionStore = async (
    keyType: SESSION_KEYS,
    key: string,
    fromDesktop?: boolean
) => {
    const cryptoWorker = await new CryptoWorker();
    const sessionKeyAttributes = await cryptoWorker.encryptToB64(key);
    setKey(keyType, sessionKeyAttributes);
    if (isElectron() && !fromDesktop) {
        safeStorageService.setEncryptionKey(key);
    }
};

export const getRecoveryKey = async () => {
    let recoveryKey: string = null;
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
                masterKey
            );
        } else {
            recoveryKey = await createNewRecoveryKey();
        }
        recoveryKey = await cryptoWorker.toHex(recoveryKey);
        return recoveryKey;
    } catch (e) {
        logError(e, 'getRecoveryKey failed');
        throw e;
    }
};

async function createNewRecoveryKey() {
    const masterKey = await getActualKey();
    const existingAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);

    const cryptoWorker = await new CryptoWorker();

    const recoveryKey: string = await cryptoWorker.generateEncryptionKey();
    const encryptedMasterKey = await cryptoWorker.encryptToB64(
        masterKey,
        recoveryKey
    );
    const encryptedRecoveryKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey
    );
    const recoveryKeyAttributes = {
        masterKeyEncryptedWithRecoveryKey: encryptedMasterKey.encryptedData,
        masterKeyDecryptionNonce: encryptedMasterKey.nonce,
        recoveryKeyEncryptedWithMasterKey: encryptedRecoveryKey.encryptedData,
        recoveryKeyDecryptionNonce: encryptedRecoveryKey.nonce,
    };
    await setRecoveryKey(getToken(), recoveryKeyAttributes);

    const updatedKeyAttributes = Object.assign(
        existingAttributes,
        recoveryKeyAttributes
    );
    setData(LS_KEYS.KEY_ATTRIBUTES, updatedKeyAttributes);

    return recoveryKey;
}
export async function decryptAndStoreToken(masterKey: string) {
    const cryptoWorker = await new CryptoWorker();
    const user = getData(LS_KEYS.USER);
    const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
    let decryptedToken = null;
    const { encryptedToken } = user;
    if (encryptedToken && encryptedToken.length > 0) {
        const secretKey = await cryptoWorker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey
        );
        const URLUnsafeB64DecryptedToken = await cryptoWorker.boxSealOpen(
            encryptedToken,
            keyAttributes.publicKey,
            secretKey
        );
        const decryptedTokenBytes = await cryptoWorker.fromB64(
            URLUnsafeB64DecryptedToken
        );
        decryptedToken = await cryptoWorker.toURLSafeB64(decryptedTokenBytes);
        setData(LS_KEYS.USER, {
            ...user,
            token: decryptedToken,
            encryptedToken: null,
        });
    }
}

export async function encryptWithRecoveryKey(key: string) {
    const cryptoWorker = await new CryptoWorker();
    const hexRecoveryKey = await getRecoveryKey();
    const recoveryKey = await cryptoWorker.fromHex(hexRecoveryKey);
    const encryptedKey = await cryptoWorker.encryptToB64(key, recoveryKey);
    return encryptedKey;
}

export async function decryptDeleteAccountChallenge(
    encryptedChallenge: string
) {
    const cryptoWorker = await new CryptoWorker();
    const masterKey = await getActualKey();
    const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
    const secretKey = await cryptoWorker.decryptB64(
        keyAttributes.encryptedSecretKey,
        keyAttributes.secretKeyDecryptionNonce,
        masterKey
    );
    const b64DecryptedChallenge = await cryptoWorker.boxSealOpen(
        encryptedChallenge,
        keyAttributes.publicKey,
        secretKey
    );
    const utf8DecryptedChallenge = atob(b64DecryptedChallenge);
    return utf8DecryptedChallenge;
}
export default CryptoWorker;
