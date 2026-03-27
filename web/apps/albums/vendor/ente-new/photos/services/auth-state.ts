import { savedAuthToken } from "ente-base/token";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod";

export interface LocalUser {
    id: number;
    email: string;
    token: string;
    isTwoFactorEnabled?: boolean;
}

const LocalUser = z.object({
    id: z.number(),
    email: z.string(),
    token: z.string(),
    isTwoFactorEnabled: z.boolean().nullish().transform(nullToUndefined),
});

export interface KeyAttributes {
    encryptedKey: string;
    keyDecryptionNonce: string;
    kekSalt: string;
    opsLimit: number;
    memLimit: number;
    publicKey: string;
    encryptedSecretKey: string;
    secretKeyDecryptionNonce: string;
    masterKeyEncryptedWithRecoveryKey?: string;
    masterKeyDecryptionNonce?: string;
    recoveryKeyEncryptedWithMasterKey?: string;
    recoveryKeyDecryptionNonce?: string;
}

const KeyAttributes = z.object({
    kekSalt: z.string(),
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
    publicKey: z.string(),
    encryptedSecretKey: z.string(),
    secretKeyDecryptionNonce: z.string(),
    memLimit: z.number(),
    opsLimit: z.number(),
    masterKeyEncryptedWithRecoveryKey: z
        .string()
        .nullish()
        .transform(nullToUndefined),
    masterKeyDecryptionNonce: z.string().nullish().transform(nullToUndefined),
    recoveryKeyEncryptedWithMasterKey: z
        .string()
        .nullish()
        .transform(nullToUndefined),
    recoveryKeyDecryptionNonce: z.string().nullish().transform(nullToUndefined),
});

const ensureTokensMatch = async (user: LocalUser | undefined) => {
    if (user?.token !== (await savedAuthToken())) {
        throw new Error("Token mismatch");
    }
};

const savedLocalUser = (): LocalUser | undefined => {
    const jsonString = localStorage.getItem("user");
    if (!jsonString) return undefined;

    const { success, data } = LocalUser.safeParse(JSON.parse(jsonString));
    if (success) void ensureTokensMatch(data);
    return success ? data : undefined;
};

const savedKeyAttributes = (): KeyAttributes | undefined => {
    const jsonString = localStorage.getItem("keyAttributes");
    if (!jsonString) return undefined;
    return KeyAttributes.parse(JSON.parse(jsonString));
};

const ensureExpectedLoggedInValue = <T>(value: T | undefined): T => {
    if (!value) throw new Error("Not logged in");
    return value;
};

export const ensureLocalUser = (): LocalUser =>
    ensureExpectedLoggedInValue(savedLocalUser());

export const ensureSavedKeyAttributes = (): KeyAttributes =>
    ensureExpectedLoggedInValue(savedKeyAttributes());
