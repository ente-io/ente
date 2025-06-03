import { expose } from "comlink";
import { logUnhandledErrorsAndRejectionsInWorker } from "ente-base/log-web";
import * as ei from "./ente-impl";
import * as libsodium from "./libsodium";

/**
 * A web worker that exposes some of the functions defined in either the Ente
 * specific layer (ente-base/crypto) or the libsodium layer
 * (ente-base/crypto/libsodium.ts).
 *
 * See: [Note: Crypto code hierarchy].
 *
 * Note: Keep these methods logic free. They are meant to be trivial proxies.
 */
export class CryptoWorker {
    toB64 = ei._toB64;
    toB64URLSafe = ei._toB64URLSafe;
    fromB64 = ei._fromB64;
    toHex = ei._toHex;
    fromHex = ei._fromHex;
    generateKey = ei._generateKey;
    generateBlobOrStreamKey = ei._generateBlobOrStreamKey;
    encryptBoxB64 = ei._encryptBoxB64;
    encryptThumbnail = ei._encryptThumbnail;
    encryptBlobB64 = ei._encryptBlobB64;
    encryptStreamBytes = ei._encryptStreamBytes;
    initChunkEncryption = ei._initChunkEncryption;
    encryptStreamChunk = ei._encryptStreamChunk;
    encryptMetadataJSON_New = ei._encryptMetadataJSON_New;
    encryptMetadataJSON = ei._encryptMetadataJSON;
    decryptBox = ei._decryptBox;
    decryptBoxB64 = ei._decryptBoxB64;
    decryptBlob = ei._decryptBlob;
    decryptBlobB64 = ei._decryptBlobB64;
    decryptThumbnail = ei._decryptThumbnail;
    decryptStreamBytes = ei._decryptStreamBytes;
    initChunkDecryption = ei._initChunkDecryption;
    decryptStreamChunk = ei._decryptStreamChunk;
    decryptMetadataJSON_New = ei._decryptMetadataJSON_New;
    decryptMetadataJSON = ei._decryptMetadataJSON;
    chunkHashInit = ei._chunkHashInit;
    chunkHashUpdate = ei._chunkHashUpdate;
    chunkHashFinal = ei._chunkHashFinal;
    generateKeyPair = ei._generateKeyPair;
    boxSeal = ei._boxSeal;
    boxSealOpen = ei._boxSealOpen;
    deriveKey = ei._deriveKey;
    deriveSensitiveKey = ei._deriveSensitiveKey;
    deriveInteractiveKey = ei._deriveInteractiveKey;

    // TODO: -- AUDIT BELOW --

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

    async generateSaltToDeriveKey() {
        return libsodium.generateSaltToDeriveKey();
    }

    async generateSubKey(
        key: string,
        subKeyLength: number,
        subKeyID: number,
        context: string,
    ) {
        return libsodium.generateSubKey(key, subKeyLength, subKeyID, context);
    }
}

expose(CryptoWorker);

logUnhandledErrorsAndRejectionsInWorker();
