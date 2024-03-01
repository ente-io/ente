import { setRecoveryKey } from "@ente/accounts/api/user";
import { logError } from "@ente/shared/sentry";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { SESSION_KEYS, setKey } from "@ente/shared/storage/sessionStorage";
import { getActualKey } from "@ente/shared/user";
import { KeyAttributes } from "@ente/shared/user/types";
import isElectron from "is-electron";
import ComlinkCryptoWorker from ".";
import ElectronAPIs from "../electron";
import { addLogLine } from "../logging";

const LOGIN_SUB_KEY_LENGTH = 32;
const LOGIN_SUB_KEY_ID = 1;
const LOGIN_SUB_KEY_CONTEXT = "loginctx";
const LOGIN_SUB_KEY_BYTE_LENGTH = 16;

export async function decryptAndStoreToken(
    keyAttributes: KeyAttributes,
    masterKey: string,
) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const user = getData(LS_KEYS.USER);
    let decryptedToken = null;
    const { encryptedToken } = user;
    if (encryptedToken && encryptedToken.length > 0) {
        const secretKey = await cryptoWorker.decryptB64(
            keyAttributes.encryptedSecretKey,
            keyAttributes.secretKeyDecryptionNonce,
            masterKey,
        );
        const urlUnsafeB64DecryptedToken = await cryptoWorker.boxSealOpen(
            encryptedToken,
            keyAttributes.publicKey,
            secretKey,
        );
        const decryptedTokenBytes = await cryptoWorker.fromB64(
            urlUnsafeB64DecryptedToken,
        );
        decryptedToken = await cryptoWorker.toURLSafeB64(decryptedTokenBytes);
        setData(LS_KEYS.USER, {
            ...user,
            token: decryptedToken,
            encryptedToken: null,
        });
    }
}

// We encrypt the masterKey, with an intermediate key derived from the
// passphrase (with Interactive mem and ops limits) to avoid saving it to local
// storage in plain text. This means that on the web user will always have to
// enter their passphrase to access their masterKey.
export async function generateAndSaveIntermediateKeyAttributes(
    passphrase: string,
    existingKeyAttributes: KeyAttributes,
    key: string,
): Promise<KeyAttributes> {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const intermediateKekSalt = await cryptoWorker.generateSaltToDeriveKey();
    const intermediateKek = await cryptoWorker.deriveInteractiveKey(
        passphrase,
        intermediateKekSalt,
    );
    const encryptedKeyAttributes = await cryptoWorker.encryptToB64(
        key,
        intermediateKek.key,
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

export const generateLoginSubKey = async (kek: string) => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const kekSubKeyString = await cryptoWorker.generateSubKey(
        kek,
        LOGIN_SUB_KEY_LENGTH,
        LOGIN_SUB_KEY_ID,
        LOGIN_SUB_KEY_CONTEXT,
    );
    const kekSubKey = await cryptoWorker.fromB64(kekSubKeyString);

    // use first 16 bytes of generated kekSubKey as loginSubKey
    const loginSubKey = await cryptoWorker.toB64(
        kekSubKey.slice(0, LOGIN_SUB_KEY_BYTE_LENGTH),
    );

    return loginSubKey;
};

export const saveKeyInSessionStore = async (
    keyType: SESSION_KEYS,
    key: string,
    fromDesktop?: boolean,
) => {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const sessionKeyAttributes =
        await cryptoWorker.generateKeyAndEncryptToB64(key);
    setKey(keyType, sessionKeyAttributes);
    addLogLine("fromDesktop", fromDesktop);
    if (
        isElectron() &&
        !fromDesktop &&
        keyType === SESSION_KEYS.ENCRYPTION_KEY
    ) {
        ElectronAPIs.setEncryptionKey(key);
    }
};

export async function encryptWithRecoveryKey(key: string) {
    const cryptoWorker = await ComlinkCryptoWorker.getInstance();
    const hexRecoveryKey = await getRecoveryKey();
    const recoveryKey = await cryptoWorker.fromHex(hexRecoveryKey);
    const encryptedKey = await cryptoWorker.encryptToB64(key, recoveryKey);
    return encryptedKey;
}

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
                masterKey,
            );
        } else {
            recoveryKey = await createNewRecoveryKey();
        }
        recoveryKey = await cryptoWorker.toHex(recoveryKey);
        return recoveryKey;
    } catch (e) {
        console.log(e);
        logError(e, "getRecoveryKey failed");
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
        recoveryKey,
    );
    const encryptedRecoveryKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey,
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
        recoveryKeyAttributes,
    );
    setData(LS_KEYS.KEY_ATTRIBUTES, updatedKeyAttributes);

    return recoveryKey;
}
