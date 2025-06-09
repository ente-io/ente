import { HttpStatusCode } from "axios";
import type { KeyAttributes } from "ente-accounts/services/user";
import { deriveSubKeyBytes, sharedCryptoWorker, toB64 } from "ente-base/crypto";
import { ensureOk, publicRequestHeaders } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { ApiError, CustomError } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import { SRP, SrpClient } from "fast-srp-hap";
import { v4 as uuidv4 } from "uuid";
import type { UpdatedKey, UserVerificationResponse } from "./user";

/**
 * Derive a "password" (which is really an arbitrary binary value, not human
 * generated) for use as the SRP user password by applying a deterministic KDF
 * (Key Derivation Function) to the provided {@link kek}.
 *
 * @param kek The user's kek (key encryption key) as a base64 string.
 *
 * @returns A string that can be used as the SRP user password.
 */
export const deriveSRPPassword = async (kek: string) => {
    const kekSubKeyBytes = await deriveSubKeyBytes(kek, 32, 1, "loginctx");
    // Use the first 16 bytes (128 bits) of the KEK's KDF subkey as the SRP
    // password (instead of entire 32 bytes).
    return toB64(kekSubKeyBytes.slice(0, 16));
};

export interface SRPAttributes {
    srpUserID: string;
    srpSalt: string;
    memLimit: number;
    opsLimit: number;
    kekSalt: string;
    isEmailMFAEnabled: boolean;
}

interface GetSRPAttributesResponse {
    attributes: SRPAttributes;
}

export interface SRPSetupAttributes {
    srpSalt: string;
    srpVerifier: string;
    srpUserID: string;
    loginSubKey: string;
}

interface SetupSRPRequest {
    srpUserID: string;
    srpSalt: string;
    srpVerifier: string;
    srpA: string;
}

 interface SetupSRPResponse {
    setupID: string;
    srpB: string;
}

interface CompleteSRPSetupRequest {
    setupID: string;
    srpM1: string;
}

interface CompleteSRPSetupResponse {
    setupID: string;
    srpM2: string;
}

interface CreateSRPSessionResponse {
    sessionID: string;
    srpB: string;
}

export interface SRPVerificationResponse extends UserVerificationResponse {
    srpM2: string;
}

export interface UpdateSRPAndKeysRequest {
    srpM1: string;
    setupID: string;
    updatedKeyAttr: UpdatedKey;
    /**
     * If true (default), then all existing sessions for the user will be
     * invalidated.
     */
    logOutOtherDevices?: boolean;
}

export interface UpdateSRPAndKeysResponse {
    srpM2: string;
    setupID: string;
}

export const getSRPAttributes = async (
    email: string,
): Promise<SRPAttributes | null> => {
    try {
        const resp = await HTTPService.get(
            await apiURL("/users/srp/attributes"),
            { email },
        );
        return (resp.data as GetSRPAttributesResponse).attributes;
    } catch (e) {
        log.error("failed to get SRP attributes", e);
        return null;
    }
};

export const startSRPSetup = async (
    token: string,
    setupSRPRequest: SetupSRPRequest,
): Promise<SetupSRPResponse> => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/setup"),
            setupSRPRequest,
            undefined,
            { "X-Auth-Token": token },
        );

        return resp.data as SetupSRPResponse;
    } catch (e) {
        log.error("failed to post SRP attributes", e);
        throw e;
    }
};

const completeSRPSetup = async (
    token: string,
    completeSRPSetupRequest: CompleteSRPSetupRequest,
) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/complete"),
            completeSRPSetupRequest,
            undefined,
            { "X-Auth-Token": token },
        );
        return resp.data as CompleteSRPSetupResponse;
    } catch (e) {
        log.error("failed to complete SRP setup", e);
        throw e;
    }
};

export const createSRPSession = async (srpUserID: string, srpA: string) => {
    const res = await fetch(await apiURL("/users/srp/create-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify({ srpUserID, srpA }),
    });
    ensureOk(res);
    const data = await res.json();
    // TODO: Use zod
    return data as CreateSRPSessionResponse;
};

export const verifySRPSession = async (
    sessionID: string,
    srpUserID: string,
    srpM1: string,
) => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/verify-session"),
            { sessionID, srpUserID, srpM1 },
            undefined,
        );
        return resp.data as SRPVerificationResponse;
    } catch (e) {
        log.error("verifySRPSession failed", e);
        if (
            e instanceof ApiError &&
            // eslint-disable-next-line @typescript-eslint/no-unsafe-enum-comparison
            e.httpStatusCode === HttpStatusCode.Unauthorized
        ) {
            // The API contract allows for a SRP verification 401 both because
            // of incorrect credentials or a non existent account.
            throw Error(CustomError.INCORRECT_PASSWORD_OR_NO_ACCOUNT);
        } else {
            throw e;
        }
    }
};

export const updateSRPAndKeys = async (
    token: string,
    updateSRPAndKeyRequest: UpdateSRPAndKeysRequest,
): Promise<UpdateSRPAndKeysResponse> => {
    try {
        const resp = await HTTPService.post(
            await apiURL("/users/srp/update"),
            updateSRPAndKeyRequest,
            undefined,
            { "X-Auth-Token": token },
        );
        return resp.data as UpdateSRPAndKeysResponse;
    } catch (e) {
        log.error("updateSRPAndKeys failed", e);
        throw e;
    }
};

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

    const srpSalt = await cryptoWorker.generateDeriveKeySalt();

    // Museum schema requires this to be a UUID.
    const srpUserID = uuidv4();

    const srpVerifierBuffer = SRP.computeVerifier(
        SRP.params["4096"],
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
        const loginSubKey = await deriveSRPPassword(kek);
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
                    SRP.params["4096"],
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
    const kek = await cryptoWorker.deriveSensitiveKey(passphrase);

    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
        await cryptoWorker.encryptBox(masterKey, kek.key);
    const {
        encryptedData: masterKeyEncryptedWithRecoveryKey,
        nonce: masterKeyDecryptionNonce,
    } = await cryptoWorker.encryptBox(masterKey, recoveryKey);
    const {
        encryptedData: recoveryKeyEncryptedWithMasterKey,
        nonce: recoveryKeyDecryptionNonce,
    } = await cryptoWorker.encryptBox(recoveryKey, masterKey);

    const keyPair = await cryptoWorker.generateKeyPair();
    const {
        encryptedData: encryptedSecretKey,
        nonce: secretKeyDecryptionNonce,
    } = await cryptoWorker.encryptBox(keyPair.privateKey, masterKey);

    const loginSubKey = await deriveSRPPassword(kek.key);

    const srpSetupAttributes = await generateSRPSetupAttributes(loginSubKey);

    const keyAttributes: KeyAttributes = {
        encryptedKey,
        keyDecryptionNonce,
        kekSalt: kek.salt,
        opsLimit: kek.opsLimit,
        memLimit: kek.memLimit,
        publicKey: keyPair.publicKey,
        encryptedSecretKey,
        secretKeyDecryptionNonce,
        masterKeyEncryptedWithRecoveryKey,
        masterKeyDecryptionNonce,
        recoveryKeyEncryptedWithMasterKey,
        recoveryKeyDecryptionNonce,
    };

    return { keyAttributes, masterKey, srpSetupAttributes };
}
