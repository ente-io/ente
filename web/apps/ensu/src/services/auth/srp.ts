import {
    replaceSavedLocalUser,
    saveKeyAttributes,
} from "ente-accounts/services/accounts-db";
import { ensureOk, publicRequestHeaders } from "ente-base/http";
import log from "ente-base/log";
import { apiURL } from "ente-base/origins";
import { saveAuthToken } from "ente-base/token";
import { z } from "zod";
import { saveMasterKeyInSession } from "../session";
import { ensureCryptoInit, enteWasm } from "../wasm";

/** Minimal SRP attributes needed for login. */
export const RemoteSRPAttributes = z.object({
    srpUserID: z.string(),
    srpSalt: z.string(),
    memLimit: z.number(),
    opsLimit: z.number(),
    kekSalt: z.string(),
    isEmailMFAEnabled: z.boolean(),
});

export type SRPAttributes = z.infer<typeof RemoteSRPAttributes>;

/** Minimal key attributes needed for decrypting secrets. */
export const RemoteKeyAttributes = z
    .object({
        kekSalt: z.string(),
        encryptedKey: z.string(),
        keyDecryptionNonce: z.string(),
        publicKey: z.string(),
        encryptedSecretKey: z.string(),
        secretKeyDecryptionNonce: z.string(),
        memLimit: z.number(),
        opsLimit: z.number(),

        // Optional recovery-related attributes (present for newer accounts).
        masterKeyEncryptedWithRecoveryKey: z.string().optional().nullable(),
        masterKeyDecryptionNonce: z.string().optional().nullable(),
        recoveryKeyEncryptedWithMasterKey: z.string().optional().nullable(),
        recoveryKeyDecryptionNonce: z.string().optional().nullable(),
    })
    // We only care about the fields above; ignore any extra fields.
    .loose();

export type KeyAttributes = z.infer<typeof RemoteKeyAttributes>;

const RemoteSRPVerificationResponse = z.object({
    id: z.number(),
    keyAttributes: RemoteKeyAttributes.optional().nullable(),
    encryptedToken: z.string().optional().nullable(),
    token: z.string().optional().nullable(),
    twoFactorSessionID: z.string().optional().nullable(),
    passkeySessionID: z.string().optional().nullable(),
    accountsUrl: z.string().optional().nullable(),
    twoFactorSessionIDV2: z.string().optional().nullable(),
    srpM2: z.string(),
});

type SRPVerificationResponse = z.infer<typeof RemoteSRPVerificationResponse>;

const CreateSRPSessionResponse = z.object({
    sessionID: z.string(),
    srpB: z.string(),
});

type CreateSRPSessionResponse = z.infer<typeof CreateSRPSessionResponse>;

export class SRPLoginError extends Error {
    constructor(
        public code:
            | "SRP_NOT_AVAILABLE"
            | "EMAIL_MFA_ENABLED"
            | "INCORRECT_PASSWORD"
            | "TWO_FACTOR_REQUIRED"
            | "MISSING_KEY_ATTRIBUTES"
            | "MISSING_TOKEN"
            | "DECRYPT_FAILED"
            | "INVALID_RESPONSE",
        message: string,
    ) {
        super(message);
        this.name = "SRPLoginError";
    }
}

/**
 * Fetch SRP attributes for a user.
 *
 * Returns undefined if SRP isn't setup (or the user doesn't exist).
 */
export const getSRPAttributes = async (
    email: string,
): Promise<SRPAttributes | undefined> => {
    const res = await fetch(await apiURL("/users/srp/attributes", { email }), {
        headers: publicRequestHeaders(),
    });
    if (res.status == 404) return undefined;
    ensureOk(res);

    const body = z
        .object({ attributes: RemoteSRPAttributes })
        .parse(await res.json());
    return body.attributes;
};

const createSRPSession = async (req: {
    srpUserID: string;
    srpA: string;
}): Promise<CreateSRPSessionResponse> => {
    const res = await fetch(await apiURL("/users/srp/create-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify(req),
    });
    ensureOk(res);
    return CreateSRPSessionResponse.parse(await res.json());
};

const verifySRPSession = async (req: {
    sessionID: string;
    srpUserID: string;
    srpM1: string;
}): Promise<SRPVerificationResponse> => {
    const res = await fetch(await apiURL("/users/srp/verify-session"), {
        method: "POST",
        headers: publicRequestHeaders(),
        body: JSON.stringify(req),
    });

    if (res.status == 401) {
        throw new SRPLoginError(
            "INCORRECT_PASSWORD",
            "Incorrect password or no account",
        );
    }

    ensureOk(res);
    return RemoteSRPVerificationResponse.parse(await res.json());
};

const isWasmError = (
    error: unknown,
): error is { code?: string; message?: string } =>
    typeof error === "object" && error !== null && "code" in error;

/**
 * Perform SRP login and persist token + key attributes + master key.
 */
export const loginWithSRP = async (
    email: string,
    password: string,
    srpAttributesOverride?: SRPAttributes,
) => {
    try {
        const srpAttributes =
            srpAttributesOverride ?? (await getSRPAttributes(email));
        if (!srpAttributes) {
            throw new SRPLoginError(
                "SRP_NOT_AVAILABLE",
                "This account is not configured for SRP login.",
            );
        }

        if (srpAttributes.isEmailMFAEnabled) {
            throw new SRPLoginError(
                "EMAIL_MFA_ENABLED",
                "This account requires email verification instead of SRP.",
            );
        }

        await ensureCryptoInit();
        const wasm = await enteWasm();

        // 1) Derive KEK + SRP login key.
        const creds = await wasm.auth_derive_srp_credentials(
            password,
            srpAttributes,
        );

        // 2) SRP handshake.
        const session = new wasm.SrpSession(
            srpAttributes.srpUserID,
            srpAttributes.srpSalt,
            creds.login_key,
        );

        const { sessionID, srpB } = await createSRPSession({
            srpUserID: srpAttributes.srpUserID,
            srpA: await session.public_a(),
        });

        const srpM1 = await session.compute_m1(srpB);

        const response = await verifySRPSession({
            sessionID,
            srpUserID: srpAttributes.srpUserID,
            srpM1,
        });

        // 3) Verify server proof.
        await session.verify_m2(response.srpM2);

        // 4) Handle second factor (not supported in this initial web client).
        if (
            response.passkeySessionID ||
            response.twoFactorSessionID ||
            response.twoFactorSessionIDV2
        ) {
            throw new SRPLoginError(
                "TWO_FACTOR_REQUIRED",
                "Second factor verification is required but is not supported in Ensu web yet.",
            );
        }

        const keyAttributes = response.keyAttributes ?? undefined;
        if (!keyAttributes) {
            throw new SRPLoginError(
                "MISSING_KEY_ATTRIBUTES",
                "Server did not return key attributes.",
            );
        }

        const normalizedKeyAttributes = {
            ...keyAttributes,
            masterKeyEncryptedWithRecoveryKey:
                keyAttributes.masterKeyEncryptedWithRecoveryKey ?? undefined,
            masterKeyDecryptionNonce:
                keyAttributes.masterKeyDecryptionNonce ?? undefined,
            recoveryKeyEncryptedWithMasterKey:
                keyAttributes.recoveryKeyEncryptedWithMasterKey ?? undefined,
            recoveryKeyDecryptionNonce:
                keyAttributes.recoveryKeyDecryptionNonce ?? undefined,
        };

        // 5) Decrypt secrets.
        let masterKey: string;
        let token: string;

        if (response.encryptedToken) {
            const secrets = await wasm.auth_decrypt_secrets(
                creds.kek,
                normalizedKeyAttributes,
                response.encryptedToken,
            );
            masterKey = secrets.master_key;
            token = secrets.token;
        } else if (response.token) {
            const keys = await wasm.auth_decrypt_keys_only(
                creds.kek,
                normalizedKeyAttributes,
            );
            masterKey = keys.master_key;
            token = response.token;
        } else {
            throw new SRPLoginError(
                "MISSING_TOKEN",
                "Server did not return an auth token.",
            );
        }

        // 6) Persist.
        await saveAuthToken(token);
        replaceSavedLocalUser({
            id: response.id,
            email,
            token,
            isTwoFactorEnabled: false,
        });
        saveKeyAttributes(normalizedKeyAttributes);

        await saveMasterKeyInSession(masterKey);

        return { id: response.id, email, token };
    } catch (error) {
        if (error instanceof SRPLoginError) {
            log.error("SRP login failed", error);
            console.error("SRP login failed", error);
            throw error;
        }

        if (error instanceof z.ZodError) {
            log.error("SRP login failed: invalid response", error);
            console.error("SRP login failed: invalid response", error);
            throw new SRPLoginError(
                "INVALID_RESPONSE",
                "Unexpected response from server. Please try again.",
            );
        }

        if (isWasmError(error)) {
            const code = error.code ?? "";
            const message = error.message ?? "Unknown error";

            log.error("SRP login failed (wasm)", error);
            console.error("SRP login failed (wasm)", error);

            if (code == "incorrect_password") {
                throw new SRPLoginError("INCORRECT_PASSWORD", message);
            }

            throw new SRPLoginError("DECRYPT_FAILED", message);
        }

        log.error("SRP login failed", error);
        console.error("SRP login failed", error);
        throw error;
    }
};
