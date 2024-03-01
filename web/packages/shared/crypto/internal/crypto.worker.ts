import * as libsodium from "@ente/shared/crypto/internal/libsodium";
import * as Comlink from "comlink";
import { StateAddress } from "libsodium-wrappers";

const textDecoder = new TextDecoder();
const textEncoder = new TextEncoder();
export class DedicatedCryptoWorker {
    async decryptMetadata(
        encryptedMetadata: string,
        header: string,
        key: string,
    ) {
        const encodedMetadata = await libsodium.decryptChaChaOneShot(
            await libsodium.fromB64(encryptedMetadata),
            await libsodium.fromB64(header),
            key,
        );
        return JSON.parse(textDecoder.decode(encodedMetadata));
    }

    async decryptThumbnail(
        fileData: Uint8Array,
        header: Uint8Array,
        key: string,
    ) {
        return libsodium.decryptChaChaOneShot(fileData, header, key);
    }

    async decryptEmbedding(
        encryptedEmbedding: string,
        header: string,
        key: string,
    ) {
        const encodedEmbedding = await libsodium.decryptChaChaOneShot(
            await libsodium.fromB64(encryptedEmbedding),
            await libsodium.fromB64(header),
            key,
        );
        return Float32Array.from(
            JSON.parse(textDecoder.decode(encodedEmbedding)),
        );
    }

    async decryptFile(fileData: Uint8Array, header: Uint8Array, key: string) {
        return libsodium.decryptChaCha(fileData, header, key);
    }

    async encryptMetadata(metadata: Object, key: string) {
        const encodedMetadata = textEncoder.encode(JSON.stringify(metadata));

        const { file: encryptedMetadata } =
            await libsodium.encryptChaChaOneShot(encodedMetadata, key);
        const { encryptedData, ...other } = encryptedMetadata;
        return {
            file: {
                encryptedData: await libsodium.toB64(encryptedData),
                ...other,
            },
            key,
        };
    }

    async encryptThumbnail(fileData: Uint8Array, key: string) {
        return libsodium.encryptChaChaOneShot(fileData, key);
    }

    async encryptEmbedding(embedding: Float32Array, key: string) {
        const encodedEmbedding = textEncoder.encode(
            JSON.stringify(Array.from(embedding)),
        );
        const { file: encryptEmbedding } = await libsodium.encryptChaChaOneShot(
            encodedEmbedding,
            key,
        );
        const { encryptedData, ...other } = encryptEmbedding;
        return {
            file: {
                encryptedData: await libsodium.toB64(encryptedData),
                ...other,
            },
            key,
        };
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

    async toURLSafeB64(data: Uint8Array) {
        return libsodium.toURLSafeB64(data);
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

Comlink.expose(DedicatedCryptoWorker, self);
