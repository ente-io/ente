import { sharedCryptoWorker } from "ente-base/crypto";
import log from "ente-base/log";
import { generateLoginSubKey } from "ente-shared/crypto/helpers";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import type { KeyAttributes } from "ente-shared/user/types";
import { SRP, SrpClient } from "fast-srp-hap";
import { v4 as uuidv4 } from "uuid";
import {
    completeSRPSetup,
    createSRPSession,
    startSRPSetup,
    verifySRPSession,
    type SRPAttributes,
    type SRPSetupAttributes,
} from "./srp-remote";
import type { UserVerificationResponse } from "./user";

const SRP_PARAMS = SRP.params["4096"];

export const configureSRP = async ({
    srpSalt,
    srpUserID,
    srpVerifier,
    loginSubKey,
}: SRPSetupAttributes) => {
    try {
        const srpClient = await generateSRPClient(
            srpSalt,
            srpUserID,
            loginSubKey,
        );

        const srpA = convertBufferToBase64(srpClient.computeA());

        log.debug(() => `srp a: ${srpA}`);
        const token = getToken();
        const { setupID, srpB } = await startSRPSetup(token, {
            srpA,
            srpUserID,
            srpSalt,
            srpVerifier,
        });

        srpClient.setB(convertBase64ToBuffer(srpB));

        const srpM1 = convertBufferToBase64(srpClient.computeM1());

        const { srpM2 } = await completeSRPSetup(token, { srpM1, setupID });

        srpClient.checkM2(convertBase64ToBuffer(srpM2));
    } catch (e) {
        log.error("Failed to configure SRP", e);
        throw e;
    }
};

export const generateSRPSetupAttributes = async (
    loginSubKey: string,
): Promise<SRPSetupAttributes> => {
    const cryptoWorker = await sharedCryptoWorker();

    const srpSalt = await cryptoWorker.generateSaltToDeriveKey();

    // Museum schema requires this to be a UUID.
    const srpUserID = uuidv4();

    const srpVerifierBuffer = SRP.computeVerifier(
        SRP_PARAMS,
        convertBase64ToBuffer(srpSalt),
        Buffer.from(srpUserID),
        convertBase64ToBuffer(loginSubKey),
    );

    const srpVerifier = convertBufferToBase64(srpVerifierBuffer);

    const result = { srpUserID, srpSalt, srpVerifier, loginSubKey };

    log.debug(
        () => `SRP setup attributes generated: ${JSON.stringify(result)}`,
    );

    return result;
};

export const loginViaSRP = async (
    srpAttributes: SRPAttributes,
    kek: string,
): Promise<UserVerificationResponse> => {
    try {
        const loginSubKey = await generateLoginSubKey(kek);
        const srpClient = await generateSRPClient(
            srpAttributes.srpSalt,
            srpAttributes.srpUserID,
            loginSubKey,
        );
        const srpA = srpClient.computeA();
        const { srpB, sessionID } = await createSRPSession(
            srpAttributes.srpUserID,
            convertBufferToBase64(srpA),
        );
        srpClient.setB(convertBase64ToBuffer(srpB));

        const m1 = srpClient.computeM1();
        log.debug(() => `srp m1: ${convertBufferToBase64(m1)}`);
        const { srpM2, ...rest } = await verifySRPSession(
            sessionID,
            srpAttributes.srpUserID,
            convertBufferToBase64(m1),
        );
        log.debug(() => `srp verify session successful,srpM2: ${srpM2}`);

        srpClient.checkM2(convertBase64ToBuffer(srpM2));

        log.debug(() => `srp server verify successful`);
        return rest;
    } catch (e) {
        log.error("srp verify failed", e);
        throw e;
    }
};

// ====================
// HELPERS
// ====================

export const generateSRPClient = async (
    srpSalt: string,
    srpUserID: string,
    loginSubKey: string,
) => {
    return new Promise<SrpClient>((resolve, reject) => {
        SRP.genKey(function (err, secret1) {
            try {
                if (err) {
                    reject(err);
                }
                if (!secret1) {
                    throw Error("secret1 gen failed");
                }
                const srpClient = new SrpClient(
                    SRP_PARAMS,
                    convertBase64ToBuffer(srpSalt),
                    Buffer.from(srpUserID),
                    convertBase64ToBuffer(loginSubKey),
                    secret1,
                    false,
                );

                resolve(srpClient);
            } catch (e) {
                // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors
                reject(e);
            }
        });
    });
};

export const convertBufferToBase64 = (buffer: Buffer) => {
    return buffer.toString("base64");
};

export const convertBase64ToBuffer = (base64: string) => {
    return Buffer.from(base64, "base64");
};

export async function generateKeyAndSRPAttributes(
    passphrase: string,
): Promise<{
    keyAttributes: KeyAttributes;
    masterKey: string;
    srpSetupAttributes: SRPSetupAttributes;
}> {
    const cryptoWorker = await sharedCryptoWorker();
    const masterKey = await cryptoWorker.generateKey();
    const recoveryKey = await cryptoWorker.generateKey();
    const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
    const kek = await cryptoWorker.deriveSensitiveKey(passphrase, kekSalt);

    const masterKeyEncryptedWithKek = await cryptoWorker.encryptToB64(
        masterKey,
        kek.key,
    );
    const masterKeyEncryptedWithRecoveryKey = await cryptoWorker.encryptToB64(
        masterKey,
        recoveryKey,
    );
    const recoveryKeyEncryptedWithMasterKey = await cryptoWorker.encryptToB64(
        recoveryKey,
        masterKey,
    );

    const keyPair = await cryptoWorker.generateKeyPair();
    const encryptedKeyPairAttributes = await cryptoWorker.encryptToB64(
        keyPair.privateKey,
        masterKey,
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

    return { keyAttributes, masterKey, srpSetupAttributes };
}
