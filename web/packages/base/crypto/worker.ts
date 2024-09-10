import { expose } from "comlink";
import type { StateAddress } from "libsodium-wrappers-sumo";
import * as ei from "./ente-impl";
import * as libsodium from "./libsodium";

/**
 * A web worker that exposes some of the functions defined in either the Ente
 * specific layer (@/base/crypto) or the libsodium layer
 * (@/base/crypto/libsodium.ts).
 *
 * See: [Note: Crypto code hierarchy].
 *
 * Note: Keep these methods logic free. They are meant to be trivial proxies.
 */
export class CryptoWorker {
    encryptBoxB64 = ei._encryptBoxB64;
    encryptThumbnail = ei._encryptThumbnail;
    encryptMetadataJSON_New = ei._encryptMetadataJSON_New;
    encryptMetadataJSON = ei._encryptMetadataJSON;
    decryptBox = ei._decryptBox;
    decryptBoxB64 = ei._decryptBoxB64;
    decryptBlob = ei._decryptBlob;
    decryptBlobB64 = ei._decryptBlobB64;
    decryptThumbnail = ei._decryptThumbnail;
    decryptMetadataJSON_New = ei._decryptMetadataJSON_New;
    decryptMetadataJSON = ei._decryptMetadataJSON;

    // TODO: -- AUDIT BELOW --

    async decryptFile(fileData: Uint8Array, header: Uint8Array, key: string) {
        return libsodium.decryptChaCha(fileData, header, key);
    }

    async encryptFile(fileData: Uint8Array) {
        return libsodium.encryptChaCha(fileData);
    }

    async encryptFileChunk(
        data: Uint8Array,
        pushState: StateAddress,
        isFinalChunk: boolean,
    ) {
        return libsodium.encryptFileChunk(data, pushState, isFinalChunk);
    }

    async initChunkEncryption() {
        return libsodium.initChunkEncryption();
    }

    async initChunkDecryption(header: Uint8Array, key: Uint8Array) {
        return libsodium.initChunkDecryption(header, key);
    }

    async decryptFileChunk(fileData: Uint8Array, pullState: StateAddress) {
        return libsodium.decryptFileChunk(fileData, pullState);
    }

    async initChunkHashing() {
        return libsodium.initChunkHashing();
    }

    async hashFileChunk(hashState: StateAddress, chunk: Uint8Array) {
        return libsodium.hashFileChunk(hashState, chunk);
    }

    async completeChunkHashing(hashState: StateAddress) {
        return libsodium.completeChunkHashing(hashState);
    }

    async deriveKey(
        passphrase: string,
        salt: string,
        opsLimit: number,
        memLimit: number,
    ) {
        return libsodium.deriveKey(passphrase, salt, opsLimit, memLimit);
    }

    async deriveSensitiveKey(passphrase: string, salt: string) {
        return libsodium.deriveSensitiveKey(passphrase, salt);
    }

    async deriveInteractiveKey(passphrase: string, salt: string) {
        return libsodium.deriveInteractiveKey(passphrase, salt);
    }

    async decryptB64(data: string, nonce: string, key: string) {
        return libsodium.decryptB64(data, nonce, key);
    }

    async decryptToUTF8(data: string, nonce: string, key: string) {
        return libsodium.decryptToUTF8(data, nonce, key);
    }

    async encryptToB64(data: string, key: string) {
        return libsodium.encryptToB64(data, key);
    }

    async generateKeyAndEncryptToB64(data: string) {
        return libsodium.generateKeyAndEncryptToB64(data);
    }

    async encryptUTF8(data: string, key: string) {
        return libsodium.encryptUTF8(data, key);
    }

    async generateEncryptionKey() {
        return libsodium.generateEncryptionKey();
    }

    async generateSaltToDeriveKey() {
        return libsodium.generateSaltToDeriveKey();
    }

    async generateKeyPair() {
        return libsodium.generateKeyPair();
    }

    async boxSealOpen(input: string, publicKey: string, secretKey: string) {
        return libsodium.boxSealOpen(input, publicKey, secretKey);
    }

    async boxSeal(input: string, publicKey: string) {
        return libsodium.boxSeal(input, publicKey);
    }

    async generateSubKey(
        key: string,
        subKeyLength: number,
        subKeyID: number,
        context: string,
    ) {
        return libsodium.generateSubKey(key, subKeyLength, subKeyID, context);
    }

    async fromUTF8(string: string) {
        return libsodium.fromUTF8(string);
    }
    async toUTF8(data: string) {
        return libsodium.toUTF8(data);
    }

    async toB64(data: Uint8Array) {
        return libsodium.toB64(data);
    }

    async toB64URLSafe(data: Uint8Array) {
        return libsodium.toB64URLSafe(data);
    }

    async fromB64(string: string) {
        return libsodium.fromB64(string);
    }

    async toHex(string: string) {
        return libsodium.toHex(string);
    }

    async fromHex(string: string) {
        return libsodium.fromHex(string);
    }
}

expose(CryptoWorker);
