import { HttpStatusCode } from "axios";
import { deriveSubKeyBytes, sharedCryptoWorker, toB64 } from "ente-base/crypto";
import { ensureOk, publicRequestHeaders } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { ApiError, CustomError } from "ente-shared/error";
import HTTPService from "ente-shared/network/HTTPService";
import { getToken } from "ente-shared/storage/localStorage/helpers";
import { SRP, SrpClient } from "fast-srp-hap";
import { v4 as uuidv4 } from "uuid";
import type { UserVerificationResponse } from "./user";

/**
 * The SRP attributes for a user.
 *
 * [Note: SRP]
 *
 * The SRP (Secure Remote Password) protocol is a modified Diffie-Hellman key
 * exchange that allows the remote to verify the user's possession of a
 * passphrase, and the user to ensure that remote is not being impersonated,
 * without the passphrase ever leaving the device.
 *
 * It is used as an alternative to email verification flows, though the user
 * also has an option to enable it in addition to SRP.
 *
 * For more about the what and why, see the announcement blog post
 * https://ente.io/blog/ente-adopts-secure-remote-passwords/
 *
 * Here we do not focus on the math (the above blog post links to reference
 * material, and there is also an RFC), but instead of the various bits of
 * information that get exchanged.
 *
 * Broadly, there are two scenarios: SRP setup, and SRP verification.
 *
 * [Note: SRP setup]
 *
 * During SRP setup, client generates
 *
 * 01. A SRP user ID (a new UUID-v4)
 * 02. A SRP password (deterministically derived from their regular KEK)
 * 03. A SRP salt (randomly generated)
 *
 * These 3 things are enough to create a SRP verifier and client
 *
 * 04. verifier = computeSRPVerifier({ userID, password, salt })
 * 05. client = new SRPClient({ userID, password, salt })
 *
 * The SRP client can just be thought of an ephemeral stateful mechanism to
 * avoid passing all the state accrued so far to each operation.
 *
 * The client (app) then starts the setup ceremony with remote:
 *
 * 06. Use SRP client to conjure secret `a` and use that to compute a public A
 * 07. Send { userID, salt, verifier, A } to remote ("/users/srp/setup")
 *
 * Remote then:
 *
 * 08. Generates a SRP serverKey (random)
 * 09. Saves { userID, serverKey, A } into SRP sessions table
 * 10. Creates server = new SRPServer({ verifier, serverKey })
 * 11. Uses SRP server to conjure secret `b` and use that to compute a public B
 * 12. Stashes { sessionID, userID, salt, verifier } into SRP setups table
 * 13. Returns { setupID, B } to client
 *
 * Client then
 *
 * 14. Tells its SRP client about B
 * 15. Computes SRP M1 (evidence message) using the SRP client
 * 16. Sends { setupID, M1 } to remote ("/users/srp/complete")
 *
 * Remote then
 *
 * 17. Uses setupID to read the stashed { sessionID, userID, salt, verifier }
 * 18. Uses sessionID to read { serverKey, A }
 * 19. Recreates server = new SRPServer({ verifier, serverKey }), sets server.A
 * 20. Verifies M1 using the SRP server, obtaining a SRP M2 (evidence message)
 * 21. Returns M2
 *
 * Client then
 *
 * 22. Verifies M2
 *
 * SRP setup is now complete.
 *
 * A similar flow is used when the user changes their passphrase. On passphrase
 * change, a new KEK is generated, thus the SRP password also changes, and so a
 * subset of the steps above are done to update both client and remote.
 */
export interface SRPAttributes {
    srpUserID: string;
    srpSalt: string;
    memLimit: number;
    opsLimit: number;
    kekSalt: string;
    isEmailMFAEnabled: boolean;
}

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

export interface UpdatedKeyAttr {
    kekSalt: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    opsLimit: number;
    memLimit: number;
}

export interface UpdateSRPAndKeysRequest {
    srpM1: string;
    setupID: string;
    updatedKeyAttr: UpdatedKeyAttr;
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

export const configureSRP = async (attr: SRPSetupAttributes) =>
    srpSetupOrReconfigure(attr, (cbAttr) =>
        completeSRPSetup(getToken(), cbAttr),
    );

export const srpSetupOrReconfigure = async (
    { srpSalt, srpUserID, srpVerifier, loginSubKey }: SRPSetupAttributes,
    cb: ({
        setupID,
        srpM1,
    }: {
        setupID: string;
        srpM1: string;
    }) => Promise<{ srpM2: string }>,
) => {
    const srpClient = await generateSRPClient(srpSalt, srpUserID, loginSubKey);

    const srpA = convertBufferToBase64(srpClient.computeA());

    const token = getToken();
    const { setupID, srpB } = await startSRPSetup(token, {
        srpA,
        srpUserID,
        srpSalt,
        srpVerifier,
    });

    srpClient.setB(convertBase64ToBuffer(srpB));

    const srpM1 = convertBufferToBase64(srpClient.computeM1());

    const { srpM2 } = await cb({ srpM1, setupID });

    srpClient.checkM2(convertBase64ToBuffer(srpM2));
};

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

/**
 *
 * @param loginSubKey The user's SRP password (autogenerated, derived
 * deterministically from their kek by {@link deriveSRPPassword}).
 *
 * @returns
 */
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
