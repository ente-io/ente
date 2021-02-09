import * as Comlink from 'comlink';
import * as libsodium from 'utils/crypto/libsodium';

export class Crypto {
    async decryptMetadata(file) {
        const encodedMetadata = await libsodium.decryptChaChaOneShot(
            await libsodium.fromB64(file.metadata.encryptedData),
            await libsodium.fromB64(file.metadata.decryptionHeader),
            file.key
        );
        return JSON.parse(new TextDecoder().decode(encodedMetadata));
    }

    async decryptThumbnail(fileData, header, key) {
        return libsodium.decryptChaChaOneShot(fileData, header, key);
    }

    async decryptFile(fileData, header, key) {
        return libsodium.decryptChaCha(fileData, header, key);
    }

    async encryptMetadata(metadata, key) {
        const encodedMetadata = new TextEncoder().encode(
            JSON.stringify(metadata)
        );

        const {
            file: encryptedMetadata,
        } = await libsodium.encryptChaChaOneShot(encodedMetadata, key);
        const { encryptedData, ...other } = encryptedMetadata;
        return {
            file: {
                encryptedData: await libsodium.toB64(encryptedData),
                ...other,
            },
            key,
        };
    }

    async encryptThumbnail(fileData, key) {
        return libsodium.encryptChaChaOneShot(fileData, key);
    }

    async encryptFile(fileData, key) {
        return libsodium.encryptChaCha(fileData, key);
    }

    async encrypt(data, key) {
        return libsodium.encrypt(data, key);
    }

    async decrypt(data, nonce, key) {
        return libsodium.decrypt(data, nonce, key);
    }

    async hash(input) {
        return libsodium.hash(input);
    }

    async verifyHash(hash, input) {
        return libsodium.verifyHash(hash, input);
    }

    async deriveKey(passphrase, salt) {
        return libsodium.deriveKey(passphrase, salt);
    }

    async decryptB64(data, nonce, key) {
        return libsodium.decryptB64(data, nonce, key);
    }

    async decryptString(data, nonce, key) {
        return libsodium.decryptString(data, nonce, key);
    }

    async encryptToB64(data, key) {
        return libsodium.encryptToB64(data, key);
    }

    async generateMasterKey() {
        return libsodium.generateMasterKey();
    }

    async generateSaltToDeriveKey() {
        return libsodium.generateSaltToDeriveKey();
    }

    async deriveKey(passphrase, salt) {
        return libsodium.deriveKey(passphrase, salt);
    }

    async generateKeyPair() {
        return libsodium.generateKeyPair();
    }

    async boxSealOpen(input, publicKey, secretKey) {
        return libsodium.boxSealOpen(input, publicKey, secretKey);
    }

    async fromString(string) {
        return libsodium.fromString(string);
    }

    async toB64(data) {
        return libsodium.toB64(data);
    }

    async fromB64(string) {
        return libsodium.fromB64(string);
    }
}

Comlink.expose(Crypto);
