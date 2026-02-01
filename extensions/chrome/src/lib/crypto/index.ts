/**
 * Crypto operations for Ente Auth extension.
 * Adapted from web/packages/base/crypto/libsodium.ts
 *
 * Uses dynamic import to avoid module resolution issues at build time.
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let sodium: any = null;

/**
 * Initialize libsodium. Must be called before any crypto operations.
 */
export const initCrypto = async (): Promise<void> => {
  if (sodium) return;
  const module = await import("libsodium-wrappers-sumo");
  sodium = module.default;
  await sodium.ready;
};

/**
 * Ensure sodium is initialized.
 */
const ensureSodium = async () => {
  if (!sodium) {
    await initCrypto();
  }
  return sodium;
};

/**
 * Convert bytes to base64 string.
 */
export const toB64 = async (input: Uint8Array): Promise<string> => {
  const s = await ensureSodium();
  return s.to_base64(input, s.base64_variants.ORIGINAL);
};

/**
 * Convert bytes to URL-safe base64 string.
 * Uses - and _ instead of + and / for URL compatibility.
 */
export const toB64URLSafe = async (input: Uint8Array): Promise<string> => {
  const s = await ensureSodium();
  return s.to_base64(input, s.base64_variants.URLSAFE);
};

/**
 * Convert base64 string to bytes.
 */
export const fromB64 = async (input: string): Promise<Uint8Array> => {
  const s = await ensureSodium();
  return s.from_base64(input, s.base64_variants.ORIGINAL);
};

/**
 * Convert URL-safe base64 string to bytes.
 */
export const fromB64URLSafe = async (input: string): Promise<Uint8Array> => {
  const s = await ensureSodium();
  return s.from_base64(input, s.base64_variants.URLSAFE);
};

/**
 * Helper to convert BytesOrB64 to bytes.
 */
type BytesOrB64 = Uint8Array | string;

const bytes = async (bob: BytesOrB64): Promise<Uint8Array> =>
  typeof bob === "string" ? fromB64(bob) : bob;

/**
 * Encrypted box (secretbox encryption result).
 */
export interface EncryptedBox {
  encryptedData: string;
  nonce: string;
}

/**
 * Encrypted blob (secretstream encryption result).
 */
export interface EncryptedBlob {
  encryptedData: string;
  decryptionHeader: string;
}

/**
 * Generate a new random 256-bit key.
 */
export const generateKey = async (): Promise<string> => {
  const s = await ensureSodium();
  return toB64(s.crypto_secretbox_keygen());
};

/**
 * Encrypt data using secretbox (XSalsa20-Poly1305).
 * Returns encrypted data and nonce as base64 strings.
 */
export const encryptBox = async (
  data: BytesOrB64,
  key: BytesOrB64,
): Promise<EncryptedBox> => {
  const s = await ensureSodium();
  const nonce = s.randombytes_buf(s.crypto_secretbox_NONCEBYTES);
  const encryptedData = s.crypto_secretbox_easy(
    await bytes(data),
    nonce,
    await bytes(key),
  );
  return {
    encryptedData: await toB64(encryptedData),
    nonce: await toB64(nonce),
  };
};

/**
 * Decrypt the result of encryptBox.
 * Returns decrypted data as base64 string.
 */
export const decryptBox = async (
  { encryptedData, nonce }: EncryptedBox,
  key: BytesOrB64,
): Promise<string> => {
  const s = await ensureSodium();
  const decrypted = s.crypto_secretbox_open_easy(
    await bytes(encryptedData),
    await bytes(nonce),
    await bytes(key),
  );
  return toB64(decrypted);
};

/**
 * Decrypt the result of encryptBox and return bytes.
 */
export const decryptBoxBytes = async (
  { encryptedData, nonce }: EncryptedBox,
  key: BytesOrB64,
): Promise<Uint8Array> => {
  const s = await ensureSodium();
  return s.crypto_secretbox_open_easy(
    await bytes(encryptedData),
    await bytes(nonce),
    await bytes(key),
  );
};

/**
 * Decrypt blob encrypted with secretstream (XChaCha20-Poly1305).
 * Returns decrypted bytes.
 */
export const decryptBlobBytes = async (
  { encryptedData, decryptionHeader }: EncryptedBlob,
  key: BytesOrB64,
): Promise<Uint8Array> => {
  const s = await ensureSodium();
  const pullState = s.crypto_secretstream_xchacha20poly1305_init_pull(
    await bytes(decryptionHeader),
    await bytes(key),
  );
  const pullResult = s.crypto_secretstream_xchacha20poly1305_pull(
    pullState,
    await bytes(encryptedData),
    null,
  );
  return pullResult.message;
};

/**
 * Decrypt blob and return as base64 string.
 */
export const decryptBlob = async (
  blob: EncryptedBlob,
  key: BytesOrB64,
): Promise<string> => {
  const decrypted = await decryptBlobBytes(blob, key);
  return toB64(decrypted);
};

/**
 * Decrypt metadata JSON.
 * Decrypts blob, UTF-8 decodes, and parses as JSON.
 */
export const decryptMetadataJSON = async (
  blob: EncryptedBlob,
  key: BytesOrB64,
): Promise<unknown> => {
  const decrypted = await decryptBlobBytes(blob, key);
  return JSON.parse(new TextDecoder().decode(decrypted)) as unknown;
};

/**
 * Derive a key from passphrase using Argon2id.
 *
 * @param passphrase - User's password
 * @param salt - Base64 encoded salt
 * @param opsLimit - Operations limit
 * @param memLimit - Memory limit in bytes
 * @returns Base64 encoded derived key
 */
export const deriveKey = async (
  passphrase: string,
  salt: string,
  opsLimit: number,
  memLimit: number,
): Promise<string> => {
  const s = await ensureSodium();
  const keyBytes = s.crypto_pwhash(
    s.crypto_secretbox_KEYBYTES,
    s.from_string(passphrase),
    await fromB64(salt),
    opsLimit,
    memLimit,
    s.crypto_pwhash_ALG_ARGON2ID13,
  );
  return toB64(keyBytes);
};

/**
 * Derive a subkey from a high-entropy key using libsodium KDF.
 * Used for SRP login ("loginctx").
 */
export const deriveSubKeyBytes = async (
  key: string,
  subKeyLength: number,
  subKeyID: number,
  context: string,
): Promise<Uint8Array> => {
  const s = await ensureSodium();
  return s.crypto_kdf_derive_from_key(
    subKeyLength,
    subKeyID,
    context,
    await bytes(key),
  );
};

/**
 * Derive the SRP "login sub-key" from the user's KEK.
 *
 * Mirrors the Ente web client derivation:
 * - derive subkey bytes with context "loginctx", id 1
 * - take first 16 bytes, base64 encode
 */
export const deriveSRPLoginSubKey = async (kek: string): Promise<string> => {
  const subKey = await deriveSubKeyBytes(kek, 32, 1, "loginctx");
  return toB64(subKey.slice(0, 16));
};

/**
 * Public key decryption (box seal open).
 * Decrypts data encrypted with boxSeal using the keypair.
 * Returns result as regular base64.
 */
export const boxSealOpen = async (
  encryptedData: string,
  publicKey: string,
  privateKey: string,
): Promise<string> => {
  const s = await ensureSodium();
  const decrypted = s.crypto_box_seal_open(
    await fromB64(encryptedData),
    await fromB64(publicKey),
    await fromB64(privateKey),
  );
  return toB64(decrypted);
};

/**
 * Public key decryption (box seal open) with URL-safe base64 output.
 * Used for decrypting auth tokens which require URL-safe encoding.
 */
export const boxSealOpenURLSafe = async (
  encryptedData: string,
  publicKey: string,
  privateKey: string,
): Promise<string> => {
  const s = await ensureSodium();
  const decrypted = s.crypto_box_seal_open(
    await fromB64(encryptedData),
    await fromB64(publicKey),
    await fromB64(privateKey),
  );
  return toB64URLSafe(decrypted);
};

/**
 * Public key encryption (box seal).
 * Encrypts data for the recipient public key and returns ciphertext as base64.
 */
export const boxSeal = async (
  data: BytesOrB64,
  publicKey: string,
): Promise<string> => {
  const s = await ensureSodium();
  const encrypted = s.crypto_box_seal(await bytes(data), await fromB64(publicKey));
  return toB64(encrypted);
};

/**
 * Decrypt the user's master key using their password.
 *
 * @param password - User's password
 * @param keyAttributes - Key attributes from server
 * @returns Decrypted master key as base64 string
 */
export const decryptMasterKey = async (
  password: string,
  keyAttributes: {
    encryptedKey: string;
    keyDecryptionNonce: string;
    kekSalt: string;
    opsLimit: number;
    memLimit: number;
  },
): Promise<string> => {
  // Derive KEK from password
  const kek = await deriveKey(
    password,
    keyAttributes.kekSalt,
    keyAttributes.opsLimit,
    keyAttributes.memLimit,
  );

  // Decrypt master key with KEK
  return decryptBox(
    {
      encryptedData: keyAttributes.encryptedKey,
      nonce: keyAttributes.keyDecryptionNonce,
    },
    kek,
  );
};

/**
 * Decrypt the user's private key using their master key.
 *
 * @param masterKey - Decrypted master key (base64)
 * @param keyAttributes - Key attributes containing encrypted secret key
 * @returns Decrypted private key as base64 string
 */
export const decryptPrivateKey = async (
  masterKey: string,
  keyAttributes: {
    encryptedSecretKey: string;
    secretKeyDecryptionNonce: string;
  },
): Promise<string> => {
  return decryptBox(
    {
      encryptedData: keyAttributes.encryptedSecretKey,
      nonce: keyAttributes.secretKeyDecryptionNonce,
    },
    masterKey,
  );
};

/**
 * Decrypt the authenticator key using the master key.
 *
 * @param encryptedKey - Base64 encoded encrypted authenticator key
 * @param header - Base64 encoded nonce/header
 * @param masterKey - Decrypted master key (base64)
 * @returns Decrypted authenticator key as base64 string
 */
export const decryptAuthenticatorKey = async (
  encryptedKey: string,
  header: string,
  masterKey: string,
): Promise<string> => {
  return decryptBox(
    {
      encryptedData: encryptedKey,
      nonce: header,
    },
    masterKey,
  );
};

/**
 * Decrypt an authenticator entity.
 *
 * @param encryptedData - Base64 encoded encrypted data
 * @param header - Base64 encoded decryption header
 * @param authenticatorKey - Decrypted authenticator key (base64)
 * @returns Decrypted OTPAuth URI string
 */
export const decryptAuthenticatorEntity = async (
  encryptedData: string,
  header: string,
  authenticatorKey: string,
): Promise<string> => {
  const decrypted = await decryptMetadataJSON(
    {
      encryptedData,
      decryptionHeader: header,
    },
    authenticatorKey,
  );
  return decrypted as string;
};
