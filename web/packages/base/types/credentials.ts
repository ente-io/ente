import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

// TODO: Provide types
/**
 * Zod schema for {@link KeyAttributes}.
 */
export const KeyAttributes = z.object({
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

/**
 * The result of a successful two factor verification (totp or passkey).
 */
export const TwoFactorAuthorizationResponse = z.object({
    id: z.number(),
    /** TODO: keyAttributes is guaranteed to be returned by museum, update the
     * types to reflect that. */
    keyAttributes: KeyAttributes.nullish().transform(nullToUndefined),
    /** TODO: encryptedToken is guaranteed to be returned by museum, update the
     * types to reflect that. */
    encryptedToken: z.string().nullish().transform(nullToUndefined),
});

export type TwoFactorAuthorizationResponse = z.infer<
    typeof TwoFactorAuthorizationResponse
>;
