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
    encryptBox = ei._encryptBox;
    encryptBlobBytes = ei._encryptBlobBytes;
    encryptBlob = ei._encryptBlob;
    encryptMetadataJSON = ei._encryptMetadataJSON;
    encryptStreamBytes = ei._encryptStreamBytes;
    initChunkEncryption = ei._initChunkEncryption;
    encryptStreamChunk = ei._encryptStreamChunk;
    decryptBoxBytes = ei._decryptBoxBytes;
    decryptBoxUTF8 = ei._decryptBoxUTF8;
    decryptBox = ei._decryptBox;
    decryptBlobBytes = ei._decryptBlobBytes;
    decryptBlob = ei._decryptBlob;
    decryptMetadataJSON = ei._decryptMetadataJSON;
    decryptStreamBytes = ei._decryptStreamBytes;
    initChunkDecryption = ei._initChunkDecryption;
    decryptStreamChunk = ei._decryptStreamChunk;
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

    async decryptToUTF8(data: string, nonce: string, key: string) {
        return libsodium.decryptToUTF8(data, nonce, key);
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
