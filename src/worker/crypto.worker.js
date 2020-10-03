import * as Comlink from 'comlink';
import * as libsodium from 'utils/crypto/libsodium';

export class Crypto {
    async decryptMetadata(event) {
        const { data } = event;
        const key = await libsodium.decryptToB64(
            data.metadata.decryptionParams.encryptedKey,
            data.metadata.decryptionParams.keyDecryptionNonce,
            event.key);
        const metadata = await libsodium.fromB64(await libsodium.decryptToB64(
            data.metadata.encryptedData,
            data.metadata.decryptionParams.nonce,
            key));
        return {
            ...data,
            metadata: JSON.parse(new TextDecoder().decode(metadata))
        };
    }

    async decryptThumbnail(event) {
        const { data } = event;
        const key = await libsodium.decryptToB64(
            data.thumbnail.decryptionParams.encryptedKey,
            data.thumbnail.decryptionParams.keyDecryptionNonce,
            event.key);
        const thumbnail = await libsodium.decrypt(
            new Uint8Array(data.file),
            await libsodium.fromB64(data.thumbnail.decryptionParams.nonce),
            await libsodium.fromB64(key));
        return {
            id: data.id,
            data: thumbnail,
        };
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

    async decryptToB64(encryptedKey, sessionNonce, sessionKey) {
        return await libsodium.decryptToB64(encryptedKey, sessionNonce, sessionKey)
    }

    async generateMasterKey() {
        return await libsodium.generateMasterKey();
    }

    async generateSaltToDeriveKey() {
        return await libsodium.generateSaltToDeriveKey();
    }

    async deriveKey(passphrase, salt) {
        return await libsodium.deriveKey(passphrase, salt);
    }

    async fromString(string) {
        return await libsodium.fromString(string);
    }

    async toB64(data) {
        return await libsodium.toB64(data);
    }
}

Comlink.expose(Crypto);
