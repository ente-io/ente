import { KeyAttributes, SRPSetupAttributes } from 'types/user';
import { SESSION_KEYS, setKey } from 'utils/storage/sessionStorage';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getActualKey, getToken } from 'utils/common/key';
import { setRecoveryKey } from 'services/userService';
import { logError } from 'utils/sentry';
import isElectron from 'is-electron';
import safeStorageService from 'services/electron/safeStorage';
import ComlinkCryptoWorker from 'utils/comlink/ComlinkCryptoWorker';
import { PasswordStrength } from 'constants/crypto';
import zxcvbn from 'zxcvbn';
import { SRP, SrpClient } from 'fast-srp-hap';
import { convertBase64ToBuffer, convertBufferToBase64 } from 'utils/user';
import { v4 as uuidv4 } from 'uuid';
import { addLocalLog } from 'utils/logging';

const SRP_PARAMS = SRP.params['4096'];

const LOGIN_SUB_KEY_LENGTH = 32;
const LOGIN_SUB_KEY_ID = 1;
const LOGIN_SUB_KEY_CONTEXT = 'loginctx';
const LOGIN_SUB_KEY_BYTE_LENGTH = 16;

export async function generateKeyAndSRPAttributes(passphrase: string): Promise<{
    keyAttributes: KeyAttributes;
    masterKey: string;
    srpSetupAttributes: SRPSetupAttributes;
}> {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
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

    const loginSubKey = await generateLoginSubKey(kek.key);

    const srpSetupAttributes = await generateSRPSetupAttributes(loginSubKey);

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

    return {
        keyAttributes,
        masterKey,
        srpSetupAttributes,
    };
}

// We encrypt the masterKey, with an intermediate key derived from the
// passphrase (with Interactive mem and ops limits) to avoid saving it to local
// storage in plain text. This means that on the web user will always have to
// enter their passphrase to access their masterKey.
export async function generateAndSaveIntermediateKeyAttributes(
    passphrase: string,
    existingKeyAttributes: KeyAttributes,
    key: string
): Promise<KeyAttributes> {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const intermediateKekSalt = await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek = await cryptoWorker.deriveInteractiveKey(
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
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const sessionKeyAttributes = await cryptoWorker.generateKeyAndEncryptToB64(
        key
    );
    setKey(keyType, sessionKeyAttributes);
    if (
        isElectron() &&
        !fromDesktop &&
        keyType === SESSION_KEYS.ENCRYPTION_KEY
    ) {
        safeStorageService.setEncryptionKey(key);
    }
};

export const getRecoveryKey = async () => {
    let recoveryKey: string = null;
    try {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();

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

// Used only for legacy users for whom we did not generate recovery keys during
// sign up
async function createNewRecoveryKey() {
    const masterKey = await getActualKey();
    const existingAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);

    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    const recoveryKey = await cryptoWorker.generateEncryptionKey();
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

export async function decryptAndStoreToken(
    keyAttributes: KeyAttributes,
    masterKey: string
) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const user = getData(LS_KEYS.USER);
    let decryptedToken = null;
    const { encryptedToken } = user;
    if (encryptedToken && encryptedToken.length > 0) {
        const secretKey = await cryptoWorker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey
        );
        const urlUnsafeB64DecryptedToken = await cryptoWorker.boxSealOpen(
            encryptedToken,
            keyAttributes.publicKey,
            secretKey
        );
        const decryptedTokenBytes = await cryptoWorker.fromB64(
            urlUnsafeB64DecryptedToken
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
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const hexRecoveryKey = await getRecoveryKey();
    const recoveryKey = await cryptoWorker.fromHex(hexRecoveryKey);
    const encryptedKey = await cryptoWorker.encryptToB64(key, recoveryKey);
    return encryptedKey;
}

export async function decryptDeleteAccountChallenge(
    encryptedChallenge: string
) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
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

export function estimatePasswordStrength(password: string): PasswordStrength {
    if (!password) {
        return PasswordStrength.WEAK;
    }

    const zxcvbnResult = zxcvbn(password);
    if (zxcvbnResult.score < 2) {
        return PasswordStrength.WEAK;
    } else if (zxcvbnResult.score < 3) {
        return PasswordStrength.MODERATE;
    } else {
        return PasswordStrength.STRONG;
    }
}

export const isWeakPassword = (password: string) => {
    return estimatePasswordStrength(password) === PasswordStrength.WEAK;
};

export const generateLoginSubKey = async (kek: string) => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const kekSubKeyString = await cryptoWorker.generateSubKey(
        kek,
        LOGIN_SUB_KEY_LENGTH,
        LOGIN_SUB_KEY_ID,
        LOGIN_SUB_KEY_CONTEXT
    );
    const kekSubKey = await cryptoWorker.fromB64(kekSubKeyString);

    // use first 16 bytes of generated kekSubKey as loginSubKey
    const loginSubKey = await cryptoWorker.toB64(
        kekSubKey.slice(0, LOGIN_SUB_KEY_BYTE_LENGTH)
    );

    return loginSubKey;
};

export const generateSRPSetupAttributes = async (
    loginSubKey: string
): Promise<SRPSetupAttributes> => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();

    const srpSalt = await cryptoWorker.generateSaltToDeriveKey();

    const srpUserID = uuidv4();

    const srpVerifierBuffer = SRP.computeVerifier(
        SRP_PARAMS,
        convertBase64ToBuffer(srpSalt),
        Buffer.from(srpUserID),
        convertBase64ToBuffer(loginSubKey)
    );

    const srpVerifier = convertBufferToBase64(srpVerifierBuffer);

    addLocalLog(
        () => `SRP setup attributes generated',
        ${JSON.stringify({
            srpSalt,
            srpUserID,
            srpVerifier,
            loginSubKey,
        })}`
    );

    return {
        srpUserID,
        srpSalt,
        srpVerifier,
        loginSubKey,
    };
};

export const computeVerifierHelper = (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string
) => {
    const srpVerifierBuffer = SRP.computeVerifier(
        SRP_PARAMS,
        convertBase64ToBuffer(srpSalt),
        Buffer.from(srpUserID),
        convertBase64ToBuffer(loginSubKey)
    );
    return convertBufferToBase64(srpVerifierBuffer);
};
export const generateSRPClient = async (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string
) => {
    return new Promise<SrpClient>((resolve, reject) => {
        SRP.genKey(function (err, secret1) {
            try {
                if (err) {
                    reject(err);
                }
                const srpClient = new SrpClient(
                    SRP_PARAMS,
                    convertBase64ToBuffer(srpSalt),
                    Buffer.from(srpUserID),
                    convertBase64ToBuffer(loginSubKey),
                    secret1,
                    false
                );

                resolve(srpClient);
            } catch (e) {
                reject(e);
            }
        });
    });
};
