import sodium from 'libsodium-wrappers';

const encryptionChunkSize = 4 * 1024 * 1024;

export async function decryptChaChaOneShot(data: Uint8Array, header: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(pullState, data, null);
    return pullResult.message;
}

export async function decryptChaCha(data: Uint8Array, header: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
    const decryptionChunkSize =
        encryptionChunkSize + sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
    var bytesRead = 0;
    var decryptedData = [];
    var tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
    while (tag != sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        var chunkSize = decryptionChunkSize;
        if (bytesRead + chunkSize > data.length) {
            chunkSize = data.length - bytesRead;
        }
        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(pullState, buffer);
        for (var index = 0; index < pullResult.message.length; index++) {
            decryptedData.push(pullResult.message[index]);
        }
        tag = pullResult.tag;
        bytesRead += chunkSize;
    }
    return Uint8Array.from(decryptedData);
}

export async function encryptChaChaOneShot(data: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    key = key || sodium.crypto_secretstream_xchacha20poly1305_keygen();
    let initPushResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
    let [pushState, header] = [initPushResult.state, initPushResult.header];

    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(pushState, data, null, sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL);
    return {
        key, file: {
            encryptedData: pushResult,
            decryptionHeader: await toB64(header),
            creationTime: Date.now(),
            fileType: 0
        }
    }
}

export async function encryptChaCha(data: Uint8Array, key: Uint8Array) {
    await sodium.ready;

    key = key || sodium.crypto_secretstream_xchacha20poly1305_keygen();

    let initPushResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
    let [pushState, header] = [initPushResult.state, initPushResult.header];
    let bytesRead = 0;
    let tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;

    let encryptedData = [];

    while (tag !== sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        let chunkSize = encryptionChunkSize;
        if (bytesRead + chunkSize >= data.length) {
            chunkSize = data.length - bytesRead;
            tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL;
        }

        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        bytesRead += chunkSize;
        const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(pushState, buffer, null, tag);
        for (var index = 0; index < pushResult.length; index++) {
            encryptedData.push(pushResult[index]);
        }
    }
    return {
        key, file: {
            encryptedData: new Uint8Array(encryptedData),
            decryptionHeader: await toB64(header),
            creationTime: Date.now(),
            fileType: 0
        }
    }
}

export async function encryptToB64(data: Uint8Array, key: Uint8Array) {
    await sodium.ready;

    const encrypted = await encrypt(data, key);
    
    return {
        encryptedData: await toB64(encrypted.encryptedData),
        key: await toB64(encrypted.key),
        nonce: await toB64(encrypted.nonce),
    }
}

export async function decryptToB64(data: string, nonce: string, key: string) {
    await sodium.ready;
    const decrypted = await decrypt(await fromB64(data),
        await fromB64(nonce),
        await fromB64(key))
    return await toB64(decrypted);
}

export async function encrypt(data: Uint8Array, key?: Uint8Array) {
    await sodium.ready;
    if (key == null) {
        key = sodium.crypto_secretbox_keygen();
    }
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(data, nonce, key);
    return {
        encryptedData: encryptedData,
        key: key,
        nonce: nonce,
    }
}

export async function decrypt(data: Uint8Array, nonce: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    return sodium.crypto_secretbox_open_easy(data, nonce, key);
}

export async function verifyHash(hash: string, input: Uint8Array) {
    await sodium.ready;
    return sodium.crypto_pwhash_str_verify(hash, input);
}

export async function hash(input: string | Uint8Array) {
    await sodium.ready;
    return sodium.crypto_pwhash_str(
        input,
        sodium.crypto_pwhash_OPSLIMIT_SENSITIVE,
        sodium.crypto_pwhash_MEMLIMIT_MODERATE,
    );
}

export async function deriveKey(passphrase: Uint8Array, salt: Uint8Array) {
    await sodium.ready;
    return sodium.crypto_pwhash(
        sodium.crypto_secretbox_KEYBYTES,
        passphrase,
        salt,
        sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
        sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
        sodium.crypto_pwhash_ALG_DEFAULT,
    );
}

export async function generateMasterKey() {
    await sodium.ready;
    return sodium.crypto_kdf_keygen();
}

export async function generateSaltToDeriveKey() {
    await sodium.ready;
    return sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES);
}

export async function generateKeyPair() {
    await sodium.ready;
    return sodium.crypto_box_keypair();
}

export async function boxSealOpen(input: Uint8Array, publicKey: Uint8Array, secretKey: Uint8Array) {
    await sodium.ready;
    return sodium.crypto_box_seal_open(input, publicKey, secretKey);
}

export async function fromB64(input: string) {
    await sodium.ready;
    return sodium.from_base64(input, sodium.base64_variants.ORIGINAL);
}

export async function toB64(input: Uint8Array) {
    await sodium.ready;
    return sodium.to_base64(input, sodium.base64_variants.ORIGINAL);
}

export async function fromString(input: string) {
    await sodium.ready;
    return sodium.from_string(input);
}