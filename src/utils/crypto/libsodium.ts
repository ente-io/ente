import sodium from 'libsodium-wrappers';

export async function decryptChaCha(data: Uint8Array, header: Uint8Array, key: Uint8Array) {
    await sodium.ready;
    const pullState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
    const pullResult = sodium.crypto_secretstream_xchacha20poly1305_pull(pullState, data, null);
    return pullResult.message;
}

export async function encryptToB64(data: string, key: string) {
    await sodium.ready;
    var bKey: Uint8Array;
    if (key == null) {
        bKey = sodium.crypto_secretbox_keygen();
    } else {
        bKey = await fromB64(key)
    }
    const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
    const encryptedData = sodium.crypto_secretbox_easy(data, nonce, bKey);
    return {
        encryptedData: await toB64(encryptedData),
        key: await toB64(bKey),
        nonce: await toB64(nonce),
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