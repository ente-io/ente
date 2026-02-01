import { z } from "zod";

/**
 * Key attributes returned by the server after successful authentication.
 */
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

export const KeyAttributesSchema = z.object({
  encryptedKey: z.string(),
  keyDecryptionNonce: z.string(),
  kekSalt: z.string(),
  opsLimit: z.number(),
  memLimit: z.number(),
  publicKey: z.string(),
  encryptedSecretKey: z.string(),
  secretKeyDecryptionNonce: z.string(),
  masterKeyEncryptedWithRecoveryKey: z.string().optional(),
  masterKeyDecryptionNonce: z.string().optional(),
  recoveryKeyEncryptedWithMasterKey: z.string().optional(),
  recoveryKeyDecryptionNonce: z.string().optional(),
});

/**
 * Response from email/SRP verification.
 */
export interface VerificationResponse {
  id: number;
  keyAttributes?: KeyAttributes;
  encryptedToken?: string;
  token?: string;
  twoFactorSessionID?: string;
  passkeySessionID?: string;
  twoFactorSessionIDV2?: string;
}

const nullToUndefined = <T>(v: T | null | undefined): T | undefined =>
  v == null ? undefined : v;

export const VerificationResponseSchema = z.object({
  id: z.number(),
  keyAttributes: KeyAttributesSchema.nullish().transform(nullToUndefined),
  encryptedToken: z.string().nullish().transform(nullToUndefined),
  token: z.string().nullish().transform(nullToUndefined),
  twoFactorSessionID: z.string().nullish().transform(nullToUndefined),
  passkeySessionID: z.string().nullish().transform(nullToUndefined),
  twoFactorSessionIDV2: z.string().nullish().transform(nullToUndefined),
});

/**
 * User state stored locally.
 */
export interface LocalUser {
  id: number;
  email: string;
  /**
   * Deprecated: plaintext auth token stored from older extension versions.
   *
   * Newer versions store only `encryptedToken` in local storage and keep the
   * decrypted auth token in session/in-memory only after unlocking.
   */
  token?: string;
}

/**
 * Authenticator entity key from server.
 */
export interface AuthenticatorEntityKey {
  encryptedKey: string;
  header: string;
}

export const AuthenticatorEntityKeySchema = z.object({
  encryptedKey: z.string(),
  header: z.string(),
});

/**
 * Authenticator entity change from diff endpoint.
 */
export interface AuthenticatorEntityChange {
  id: string;
  encryptedData: string | null;
  header: string | null;
  isDeleted: boolean;
  updatedAt: number;
}

export const AuthenticatorEntityChangeSchema = z.object({
  id: z.string(),
  encryptedData: z.string().nullable(),
  header: z.string().nullable(),
  isDeleted: z.boolean(),
  updatedAt: z.number(),
});

export const AuthenticatorEntityDiffResponseSchema = z.object({
  diff: z.array(AuthenticatorEntityChangeSchema),
  timestamp: z
    .number()
    .nullish()
    .transform((v) => v ?? undefined),
});
