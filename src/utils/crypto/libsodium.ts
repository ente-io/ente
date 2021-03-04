import sodium from 'libsodium-wrappers';

export const ENCRYPTION_CHUNK_SIZE = 4 * 1024 * 1024;

export async function decryptChaChaOneShot(
    data: Uint8Array,
    header: Uint8Array,
    key: string
) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(key)
    );
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
        pullState,
        data,
        null
    );
    return pullResult.message;
}

export async function decryptChaCha(
    data: Uint8Array,
    header: Uint8Array,
    key: string
) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(
        header,
        await fromB64(key)
    );
    const decryptionChunkSize =
        ENCRYPTION_CHUNK_SIZE +
        sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
    var bytesRead = 0;
    var decryptedData = [];
    var tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
    while (tag != sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        var chunkSize = decryptionChunkSize;
        if (bytesRead + chunkSize > data.length) {
            chunkSize = data.length - bytesRead;
        }
        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(
            pullState,
            buffer
        );
        for (var index = 0; index < pullResult.message.length; index++) {
            decryptedData.push(pullResult.message[index]);
        }
        tag = pullResult.tag;
        bytesRead += chunkSize;
    }
    return Uint8Array.from(decryptedData);
}

export async function encryptChaChaOneShot(data: Uint8Array, key?: string) {
    await sodium.ready;

    const uintkey: Uint8Array = key
        ? await fromB64(key)
        : sodium.crypto_secretstream_xchacha20poly1305_keygen();
    let initPushResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(
        uintkey
    );
    let [pushState, header] = [initPushResult.state, initPushResult.header];

    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
        pushState,
        data,
        null,
        sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
    );
    return {
        key: await toB64(uintkey),
        file: {
            encryptedData: pushResult,
            decryptionHeader: await toB64(header),
        },
    };
}

export async function encryptChaCha(data: Uint8Array, key?: string) {
    await sodium.ready;

    const uintkey: Uint8Array = key
        ? await fromB64(key)
        : sodium.crypto_secretstream_xchacha20poly1305_keygen();

    let initPushResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(
        uintkey
    );
    let [pushState, header] = [initPushResult.state, initPushResult.header];
    let bytesRead = 0;
    let tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;

    let encryptedData = [];

    while (tag !== sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) {
        let chunkSize = ENCRYPTION_CHUNK_SIZE;
        if (bytesRead + chunkSize >= data.length) {
            chunkSize = data.length - bytesRead;
            tag = sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL;
        }

        const buffer = data.slice(bytesRead, bytesRead + chunkSize);
        bytesRead += chunkSize;
        const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
            pushState,
            buffer,
            null,
            tag
        );
        for (var index = 0; index < pushResult.length; index++) {
            encryptedData.push(pushResult[index]);
        }
    }
    return {
        key: await toB64(uintkey),
        file: {
            encryptedData: new Uint8Array(encryptedData),
            decryptionHeader: await toB64(header),
        },
    };
}

export async function initChunkEncryption() {
    await sodium.ready;
    let key = sodium.crypto_secretstream_xchacha20poly1305_keygen();
    let initPushResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(
        key
    );
    let [pushState, header] = [initPushResult.state, initPushResult.header];
    return {
        key: await toB64(key),
        decryptionHeader: await toB64(header),
        pushState,
    };
}
export async function encryptFileChunk(
    data: Uint8Array,
    pushState: sodium.StateAddress,
    finalChunk?: boolean
) {
    await sodium.ready;

    let tag = finalChunk
        ? sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE
        : sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL;
    const pushResult = sodium.crypto_secretstream_xchacha20poly1305_push(
        pushState,
        data,
        null,
        tag
    );

    return pushResult;
}
export async function encryptToB64(data: string, key?: string) {
    await sodium.ready;
    const encrypted = await encrypt(
        await fromB64(data),
        key ? await fromB64(key) : null
    );

    return {
        encryptedData: await toB64(encrypted.encryptedData),
        key: await toB64(encrypted.key),
        nonce: await toB64(encrypted.nonce),
    };
}
export async function encryptUTF8(data: string, key?: string) {
    const b64Data = await toB64(await fromString(data));
    return await encryptToB64(b64Data, key);
}

export async function decryptB64(data: string, nonce: string, key: string) {
    await sodium.ready;
    const decrypted = await decrypt(
        await fromB64(data),
        await fromB64(nonce),
        await fromB64(key)
    );

    return await toB64(decrypted);
}

export async function decryptToUTF8(data: string, nonce: string, key: string) {
    await sodium.ready;
    const decrypted = await decrypt(
        await fromB64(data),
        await fromB64(nonce),
        await fromB64(key)
    );

    return sodium.to_string(decrypted);
}

export async function encrypt(data: Uint8Array, key?: Uint8Array) {
    await sodium.ready;
    const uintkey: Uint8Array = key ? key : sodium.crypto_secretbox_keygen();
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(data, nonce, uintkey);
    return {
        encryptedData: encryptedData,
        key: uintkey,
        nonce: nonce,
    };
}

export async function decrypt(
    data: Uint8Array,
    nonce: Uint8Array,
    key: Uint8Array
) {
    await sodium.ready;
    return sodium.crypto_secretbox_open_easy(data, nonce, key);
}

export async function verifyHash(hash: string, input: string) {
    await sodium.ready;
    return sodium.crypto_pwhash_str_verify(hash, await fromB64(input));
}

export async function hash(input: string) {
    await sodium.ready;
    return sodium.crypto_pwhash_str(
        await fromB64(input),
        sodium.crypto_pwhash_OPSLIMIT_SENSITIVE,
        sodium.crypto_pwhash_MEMLIMIT_MODERATE
    );
}

export async function deriveKey(passphrase: string, salt: string) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_pwhash(
            sodium.crypto_secretbox_KEYBYTES,
            await fromString(passphrase),
            await fromB64(salt),
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_DEFAULT
        )
    );
}

export async function generateMasterKey() {
    await sodium.ready;
    return await toB64(sodium.crypto_kdf_keygen());
}

export async function generateSaltToDeriveKey() {
    await sodium.ready;
    return await toB64(sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES));
}

export async function generateKeyPair() {
    await sodium.ready;
    const keyPair: sodium.KeyPair = sodium.crypto_box_keypair();
    return {
        privateKey: await toB64(keyPair.privateKey),
        publicKey: await toB64(keyPair.publicKey),
    };
}

export async function boxSealOpen(
    input: string,
    publicKey: string,
    secretKey: string
) {
    await sodium.ready;
    return await toB64(
        sodium.crypto_box_seal_open(
            await fromB64(input),
            await fromB64(publicKey),
            await fromB64(secretKey)
        )
    );
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
