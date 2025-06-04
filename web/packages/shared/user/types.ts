/**
 * The user's various encrypted keys and their related attributes.
 *
 * - Attributes to derive the KEK, the (master) key encryption key.
 * - Encrypted master key (with KEK)
 * - Encrypted master key (with recovery key)
 * - Encrypted recovery key (with master key).
 * - Public key and encrypted private key (with master key).
 *
 * The various "key" attributes are base64 encoded representations of the
 * underlying binary data.
 */
export interface KeyAttributes {
    /**
     * The user's master key encrypted with the key encryption key.
     *
     * Base 64 encoded.
     *
     * [Note: Key encryption key]
     *
     * The user's master key is encrypted with a "key encryption key" (lovingly
     * called a "kek" sometimes).
     *
     * The kek itself is derived from the user's passphrase.
     *
     * 1. User enters passphrase on new device.
     *
     * 2. Client derives kek from this passphrase (using the {@link kekSalt},
     *    {@link opsLimit} and {@link memLimit} as parameters for the
     *    derivation).
     *
     * 3. Client use kek to decrypt the master key from {@link encryptedKey} and
     *    {@link keyDecryptionNonce}.
     */
    encryptedKey: string;
    /**
     * The nonce used during the encryption of the master key.
     *
     * Base 64 encoded.
     *
     * @see {@link encryptedKey}.
     */
    keyDecryptionNonce: string;
    /**
     * The salt used during the derivation of the kek.
     *
     * Base 64 encoded.
     *
     * See: [Note: Key encryption key].
     */
    kekSalt: string;
    /**
     * The operation limit used during the derivation of the kek.
     *
     * The {@link opsLimit} and {@link memLimit} are complementary parameters
     * that define the amount of work done by the key derivation function. See
     * the {@link deriveKey}, {@link deriveSensitiveKey} and
     * {@link deriveInteractiveKey} functions for more detail about them.
     *
     * See: [Note: Key encryption key].
     */
    opsLimit: number;
    /**
     * The memory limit used during the derivation of the kek.
     *
     * See {@link opsLimit} for more details.
     */
    memLimit: number;
    /**
     * The user's public key (part of their public-key keypair, the other half
     * being the {@link encryptedSecretKey}).
     *
     * Base 64 encoded.
     */
    publicKey: string;
    /**
     * The user's private key (part of their public-key keypair, the other half
     * being the {@link publicKey}) encrypted with their master key.
     *
     * Base 64 encoded.
     */
    encryptedSecretKey: string;
    /**
     * The nonce used during the encryption of {@link encryptedSecretKey}.
     */
    secretKeyDecryptionNonce: string;
    /**
     * The user's master key after being encrypted with their recovery key.
     *
     * Base 64 encoded.
     *
     * This allows the user to recover their master key if they forget their
     * passphrase but still have their recovery key.
     *
     * Note: This value doesn't change after being initially created.
     */
    masterKeyEncryptedWithRecoveryKey?: string;
    /**
     * The nonce used during the encryption of
     * {@link masterKeyEncryptedWithRecoveryKey}.
     *
     * Base 64 encoded.
     */
    masterKeyDecryptionNonce?: string;
    /**
     * The user's recovery key after being encrypted with their master key.
     *
     * Base 64 encoded.
     *
     * Note: This value doesn't change after being initially created.
     */
    recoveryKeyEncryptedWithMasterKey?: string;
    /**
     * The nonce used during the encryption of
     * {@link recoveryKeyEncryptedWithMasterKey}.
     *
     * Base 64 encoded.
     */
    recoveryKeyDecryptionNonce?: string;
}

export interface User {
    id: number;
    email: string;
    token: string;
    encryptedToken: string;
    isTwoFactorEnabled: boolean;
    twoFactorSessionID: string;
}
