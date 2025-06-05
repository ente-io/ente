/** Careful when adding add other imports! */
import * as libsodium from "./libsodium";

// Trivial proxies to the actual implementation.
//
// See: [Note: Using libsodium in worker thread]

export const _toB64 = libsodium.toB64;
export const _toB64URLSafe = libsodium.toB64URLSafe;
export const _fromB64 = libsodium.fromB64;
export const _toHex = libsodium.toHex;
export const _fromHex = libsodium.fromHex;
export const _generateKey = libsodium.generateKey;
export const _generateBlobOrStreamKey = libsodium.generateBlobOrStreamKey;
export const _encryptBox = libsodium.encryptBox;
export const _encryptBoxUTF8 = libsodium.encryptBoxUTF8;
export const _encryptBlob = libsodium.encryptBlob;
export const _encryptBlobBytes = libsodium.encryptBlobBytes;
export const _encryptMetadataJSON = libsodium.encryptMetadataJSON;
export const _encryptStreamBytes = libsodium.encryptStreamBytes;
export const _initChunkEncryption = libsodium.initChunkEncryption;
export const _encryptStreamChunk = libsodium.encryptStreamChunk;
export const _decryptBox = libsodium.decryptBox;
export const _decryptBoxBytes = libsodium.decryptBoxBytes;
export const _decryptBoxUTF8 = libsodium.decryptBoxUTF8;
export const _decryptBlob = libsodium.decryptBlob;
export const _decryptBlobBytes = libsodium.decryptBlobBytes;
export const _decryptMetadataJSON = libsodium.decryptMetadataJSON;
export const _decryptStreamBytes = libsodium.decryptStreamBytes;
export const _initChunkDecryption = libsodium.initChunkDecryption;
export const _decryptStreamChunk = libsodium.decryptStreamChunk;
export const _chunkHashInit = libsodium.chunkHashInit;
export const _chunkHashUpdate = libsodium.chunkHashUpdate;
export const _chunkHashFinal = libsodium.chunkHashFinal;
export const _generateKeyPair = libsodium.generateKeyPair;
export const _boxSeal = libsodium.boxSeal;
export const _boxSealOpen = libsodium.boxSealOpen;
export const _generateDeriveKeySalt = libsodium.generateDeriveKeySalt;
export const _deriveKey = libsodium.deriveKey;
export const _deriveSensitiveKey = libsodium.deriveSensitiveKey;
export const _deriveInteractiveKey = libsodium.deriveInteractiveKey;
export const _deriveSubKey = libsodium.deriveSubKey;
