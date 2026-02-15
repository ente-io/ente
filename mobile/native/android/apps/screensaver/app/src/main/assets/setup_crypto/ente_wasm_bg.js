/**
 * Auth error.
 */
export class AuthError {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(AuthError.prototype);
        obj.__wbg_ptr = ptr;
        AuthErrorFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        AuthErrorFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_autherror_free(ptr, 0);
    }
    /**
     * A machine-readable error code.
     * @returns {string}
     */
    get code() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.autherror_code(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Human-readable error message.
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.autherror_message(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) AuthError.prototype[Symbol.dispose] = AuthError.prototype.free;

/**
 * Crypto error.
 */
export class CryptoError {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(CryptoError.prototype);
        obj.__wbg_ptr = ptr;
        CryptoErrorFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        CryptoErrorFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_cryptoerror_free(ptr, 0);
    }
    /**
     * A machine-readable error code.
     * @returns {string}
     */
    get code() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.cryptoerror_code(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Human-readable error message.
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.cryptoerror_message(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) CryptoError.prototype[Symbol.dispose] = CryptoError.prototype.free;

/**
 * A X25519 public/secret keypair.
 */
export class CryptoKeyPair {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(CryptoKeyPair.prototype);
        obj.__wbg_ptr = ptr;
        CryptoKeyPairFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        CryptoKeyPairFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_cryptokeypair_free(ptr, 0);
    }
    /**
     * @returns {string}
     */
    get public_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.cryptokeypair_public_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {string}
     */
    get secret_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.cryptokeypair_secret_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) CryptoKeyPair.prototype[Symbol.dispose] = CryptoKeyPair.prototype.free;

/**
 * Result of decrypting only the master key and secret key.
 */
export class DecryptedKeys {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(DecryptedKeys.prototype);
        obj.__wbg_ptr = ptr;
        DecryptedKeysFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        DecryptedKeysFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_decryptedkeys_free(ptr, 0);
    }
    /**
     * Master key (base64).
     * @returns {string}
     */
    get master_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.decryptedkeys_master_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Secret key (base64).
     * @returns {string}
     */
    get secret_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.decryptedkeys_secret_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) DecryptedKeys.prototype[Symbol.dispose] = DecryptedKeys.prototype.free;

/**
 * Decrypted secrets after successful authentication.
 */
export class DecryptedSecrets {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(DecryptedSecrets.prototype);
        obj.__wbg_ptr = ptr;
        DecryptedSecretsFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        DecryptedSecretsFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_decryptedsecrets_free(ptr, 0);
    }
    /**
     * Master key (base64).
     * @returns {string}
     */
    get master_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.decryptedsecrets_master_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Secret key (base64).
     * @returns {string}
     */
    get secret_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.decryptedsecrets_secret_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Auth token (URL-safe base64).
     * @returns {string}
     */
    get token() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.decryptedsecrets_token(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) DecryptedSecrets.prototype[Symbol.dispose] = DecryptedSecrets.prototype.free;

/**
 * A SecretStream (blob) encryption result.
 */
export class EncryptedBlob {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(EncryptedBlob.prototype);
        obj.__wbg_ptr = ptr;
        EncryptedBlobFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        EncryptedBlobFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_encryptedblob_free(ptr, 0);
    }
    /**
     * @returns {string}
     */
    get decryption_header() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.encryptedblob_decryption_header(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {string}
     */
    get encrypted_data() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.encryptedblob_encrypted_data(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) EncryptedBlob.prototype[Symbol.dispose] = EncryptedBlob.prototype.free;

/**
 * A SecretBox encryption result.
 *
 * Wire format is compatible with libsodium's `crypto_secretbox_easy`.
 */
export class EncryptedBox {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(EncryptedBox.prototype);
        obj.__wbg_ptr = ptr;
        EncryptedBoxFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        EncryptedBoxFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_encryptedbox_free(ptr, 0);
    }
    /**
     * @returns {string}
     */
    get encrypted_data() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.encryptedbox_encrypted_data(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {string}
     */
    get nonce() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.encryptedbox_nonce(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) EncryptedBox.prototype[Symbol.dispose] = EncryptedBox.prototype.free;

/**
 * HTTP client for making requests to the Ente API.
 */
export class HttpClient {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        HttpClientFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_httpclient_free(ptr, 0);
    }
    /**
     * GET request, returns response body as text.
     * @param {string} path
     * @returns {Promise<string>}
     */
    get(path) {
        const ptr0 = passStringToWasm0(path, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.httpclient_get(this.__wbg_ptr, ptr0, len0);
        return ret;
    }
    /**
     * Create a client with the given base URL.
     * @param {string} base_url
     */
    constructor(base_url) {
        const ptr0 = passStringToWasm0(base_url, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.httpclient_new(ptr0, len0);
        this.__wbg_ptr = ret >>> 0;
        HttpClientFinalization.register(this, this.__wbg_ptr, this);
        return this;
    }
}
if (Symbol.dispose) HttpClient.prototype[Symbol.dispose] = HttpClient.prototype.free;

/**
 * HTTP client error.
 */
export class HttpError {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(HttpError.prototype);
        obj.__wbg_ptr = ptr;
        HttpErrorFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        HttpErrorFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_httperror_free(ptr, 0);
    }
    /**
     * Error code: "network", "http", or "parse".
     * @returns {string}
     */
    get code() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.httperror_code(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Error message.
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.httperror_message(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * HTTP status code (only for "http" errors).
     * @returns {number | undefined}
     */
    get status() {
        const ret = wasm.httperror_status(this.__wbg_ptr);
        return ret === 0xFFFFFF ? undefined : ret;
    }
}
if (Symbol.dispose) HttpError.prototype[Symbol.dispose] = HttpError.prototype.free;

/**
 * SRP credentials derived from a password.
 */
export class SrpCredentials {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(SrpCredentials.prototype);
        obj.__wbg_ptr = ptr;
        SrpCredentialsFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        SrpCredentialsFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_srpcredentials_free(ptr, 0);
    }
    /**
     * Key-encryption-key (base64).
     * @returns {string}
     */
    get kek() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.srpcredentials_kek(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * SRP login key (base64, 16 bytes).
     * @returns {string}
     */
    get login_key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.srpcredentials_login_key(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) SrpCredentials.prototype[Symbol.dispose] = SrpCredentials.prototype.free;

/**
 * SRP (Secure Remote Password) session.
 *
 * This is a small state machine:
 * - Create session
 * - Send `public_a()` to server
 * - Receive `srpB` from server, compute `srpM1`
 * - Receive `srpM2` from server, verify
 */
export class SrpSession {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        SrpSessionFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_srpsession_free(ptr, 0);
    }
    /**
     * Compute the client proof M1 from the server's public value B (base64).
     * @param {string} srp_b_b64
     * @returns {string}
     */
    compute_m1(srp_b_b64) {
        let deferred3_0;
        let deferred3_1;
        try {
            const ptr0 = passStringToWasm0(srp_b_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len0 = WASM_VECTOR_LEN;
            const ret = wasm.srpsession_compute_m1(this.__wbg_ptr, ptr0, len0);
            var ptr2 = ret[0];
            var len2 = ret[1];
            if (ret[3]) {
                ptr2 = 0; len2 = 0;
                throw takeFromExternrefTable0(ret[2]);
            }
            deferred3_0 = ptr2;
            deferred3_1 = len2;
            return getStringFromWasm0(ptr2, len2);
        } finally {
            wasm.__wbindgen_free(deferred3_0, deferred3_1, 1);
        }
    }
    /**
     * Create a new SRP session.
     *
     * All inputs are base64 strings except `srp_user_id`.
     * @param {string} srp_user_id
     * @param {string} srp_salt_b64
     * @param {string} login_key_b64
     */
    constructor(srp_user_id, srp_salt_b64, login_key_b64) {
        const ptr0 = passStringToWasm0(srp_user_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(srp_salt_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(login_key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.srpsession_new(ptr0, len0, ptr1, len1, ptr2, len2);
        if (ret[2]) {
            throw takeFromExternrefTable0(ret[1]);
        }
        this.__wbg_ptr = ret[0] >>> 0;
        SrpSessionFinalization.register(this, this.__wbg_ptr, this);
        return this;
    }
    /**
     * Get the public ephemeral value A as base64.
     * @returns {string}
     */
    public_a() {
        let deferred1_0;
        let deferred1_1;
        try {
            const ret = wasm.srpsession_public_a(this.__wbg_ptr);
            deferred1_0 = ret[0];
            deferred1_1 = ret[1];
            return getStringFromWasm0(ret[0], ret[1]);
        } finally {
            wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * Verify the server proof M2 (base64).
     * @param {string} srp_m2_b64
     */
    verify_m2(srp_m2_b64) {
        const ptr0 = passStringToWasm0(srp_m2_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.srpsession_verify_m2(this.__wbg_ptr, ptr0, len0);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }
}
if (Symbol.dispose) SrpSession.prototype[Symbol.dispose] = SrpSession.prototype.free;

/**
 * Decrypt only the master key and secret key.
 *
 * Useful when the auth token is obtained separately.
 * @param {string} kek_b64
 * @param {any} key_attrs
 * @returns {DecryptedKeys}
 */
export function auth_decrypt_keys_only(kek_b64, key_attrs) {
    const ptr0 = passStringToWasm0(kek_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.auth_decrypt_keys_only(ptr0, len0, key_attrs);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return DecryptedKeys.__wrap(ret[0]);
}

/**
 * Decrypt the master key, secret key and auth token.
 *
 * `key_attrs` should be the `keyAttributes` object from the auth response.
 * `encrypted_token_b64` is the `encryptedToken` string from the auth response.
 * @param {string} kek_b64
 * @param {any} key_attrs
 * @param {string} encrypted_token_b64
 * @returns {DecryptedSecrets}
 */
export function auth_decrypt_secrets(kek_b64, key_attrs, encrypted_token_b64) {
    const ptr0 = passStringToWasm0(kek_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ptr1 = passStringToWasm0(encrypted_token_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    const ret = wasm.auth_decrypt_secrets(ptr0, len0, key_attrs, ptr1, len1);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return DecryptedSecrets.__wrap(ret[0]);
}

/**
 * Derive the key-encryption-key (KEK) from password and KEK parameters.
 *
 * Returns the KEK as base64.
 * @param {string} password
 * @param {string} kek_salt_b64
 * @param {number} mem_limit
 * @param {number} ops_limit
 * @returns {string}
 */
export function auth_derive_kek(password, kek_salt_b64, mem_limit, ops_limit) {
    let deferred4_0;
    let deferred4_1;
    try {
        const ptr0 = passStringToWasm0(password, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(kek_salt_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.auth_derive_kek(ptr0, len0, ptr1, len1, mem_limit, ops_limit);
        var ptr3 = ret[0];
        var len3 = ret[1];
        if (ret[3]) {
            ptr3 = 0; len3 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred4_0 = ptr3;
        deferred4_1 = len3;
        return getStringFromWasm0(ptr3, len3);
    } finally {
        wasm.__wbindgen_free(deferred4_0, deferred4_1, 1);
    }
}

/**
 * Derive SRP credentials (KEK + login key) from a password and SRP attributes.
 *
 * `srp_attrs` must match the shape returned by the Ente API's
 * `/users/srp/attributes` endpoint (i.e. camelCased fields).
 * @param {string} password
 * @param {any} srp_attrs
 * @returns {SrpCredentials}
 */
export function auth_derive_srp_credentials(password, srp_attrs) {
    const ptr0 = passStringToWasm0(password, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.auth_derive_srp_credentials(ptr0, len0, srp_attrs);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return SrpCredentials.__wrap(ret[0]);
}

/**
 * Seal (anonymous public-key encrypt) `data_b64` for `recipient_public_key_b64`.
 *
 * Wire format matches libsodium `crypto_box_seal`.
 * @param {string} data_b64
 * @param {string} recipient_public_key_b64
 * @returns {string}
 */
export function crypto_box_seal(data_b64, recipient_public_key_b64) {
    let deferred4_0;
    let deferred4_1;
    try {
        const ptr0 = passStringToWasm0(data_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(recipient_public_key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_box_seal(ptr0, len0, ptr1, len1);
        var ptr3 = ret[0];
        var len3 = ret[1];
        if (ret[3]) {
            ptr3 = 0; len3 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred4_0 = ptr3;
        deferred4_1 = len3;
        return getStringFromWasm0(ptr3, len3);
    } finally {
        wasm.__wbindgen_free(deferred4_0, deferred4_1, 1);
    }
}

/**
 * Open (decrypt) a sealed box.
 *
 * Returns the plaintext as base64.
 * @param {string} sealed_b64
 * @param {string} recipient_public_key_b64
 * @param {string} recipient_secret_key_b64
 * @returns {string}
 */
export function crypto_box_seal_open(sealed_b64, recipient_public_key_b64, recipient_secret_key_b64) {
    let deferred5_0;
    let deferred5_1;
    try {
        const ptr0 = passStringToWasm0(sealed_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(recipient_public_key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(recipient_secret_key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_box_seal_open(ptr0, len0, ptr1, len1, ptr2, len2);
        var ptr4 = ret[0];
        var len4 = ret[1];
        if (ret[3]) {
            ptr4 = 0; len4 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred5_0 = ptr4;
        deferred5_1 = len4;
        return getStringFromWasm0(ptr4, len4);
    } finally {
        wasm.__wbindgen_free(deferred5_0, deferred5_1, 1);
    }
}

/**
 * Decrypt a SecretStream (blob) ciphertext.
 *
 * Returns the plaintext as base64.
 * @param {string} encrypted_data_b64
 * @param {string} decryption_header_b64
 * @param {string} key_b64
 * @returns {string}
 */
export function crypto_decrypt_blob(encrypted_data_b64, decryption_header_b64, key_b64) {
    let deferred5_0;
    let deferred5_1;
    try {
        const ptr0 = passStringToWasm0(encrypted_data_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(decryption_header_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_decrypt_blob(ptr0, len0, ptr1, len1, ptr2, len2);
        var ptr4 = ret[0];
        var len4 = ret[1];
        if (ret[3]) {
            ptr4 = 0; len4 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred5_0 = ptr4;
        deferred5_1 = len4;
        return getStringFromWasm0(ptr4, len4);
    } finally {
        wasm.__wbindgen_free(deferred5_0, deferred5_1, 1);
    }
}

/**
 * Decrypt a SecretBox ciphertext using `key_b64` and `nonce_b64`.
 *
 * Returns the plaintext as base64.
 * @param {string} encrypted_data_b64
 * @param {string} nonce_b64
 * @param {string} key_b64
 * @returns {string}
 */
export function crypto_decrypt_box(encrypted_data_b64, nonce_b64, key_b64) {
    let deferred5_0;
    let deferred5_1;
    try {
        const ptr0 = passStringToWasm0(encrypted_data_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(nonce_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ptr2 = passStringToWasm0(key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len2 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_decrypt_box(ptr0, len0, ptr1, len1, ptr2, len2);
        var ptr4 = ret[0];
        var len4 = ret[1];
        if (ret[3]) {
            ptr4 = 0; len4 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred5_0 = ptr4;
        deferred5_1 = len4;
        return getStringFromWasm0(ptr4, len4);
    } finally {
        wasm.__wbindgen_free(deferred5_0, deferred5_1, 1);
    }
}

/**
 * Derive a 32-byte key from `password` using Argon2id.
 *
 * Returns the derived key as base64.
 * @param {string} password
 * @param {string} salt_b64
 * @param {number} mem_limit
 * @param {number} ops_limit
 * @returns {string}
 */
export function crypto_derive_key(password, salt_b64, mem_limit, ops_limit) {
    let deferred4_0;
    let deferred4_1;
    try {
        const ptr0 = passStringToWasm0(password, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(salt_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_derive_key(ptr0, len0, ptr1, len1, mem_limit, ops_limit);
        var ptr3 = ret[0];
        var len3 = ret[1];
        if (ret[3]) {
            ptr3 = 0; len3 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred4_0 = ptr3;
        deferred4_1 = len3;
        return getStringFromWasm0(ptr3, len3);
    } finally {
        wasm.__wbindgen_free(deferred4_0, deferred4_1, 1);
    }
}

/**
 * Derive the SRP login key from a 32-byte master key.
 *
 * Returns the 16-byte login key as base64.
 * @param {string} master_key_b64
 * @returns {string}
 */
export function crypto_derive_login_key(master_key_b64) {
    let deferred3_0;
    let deferred3_1;
    try {
        const ptr0 = passStringToWasm0(master_key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_derive_login_key(ptr0, len0);
        var ptr2 = ret[0];
        var len2 = ret[1];
        if (ret[3]) {
            ptr2 = 0; len2 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred3_0 = ptr2;
        deferred3_1 = len2;
        return getStringFromWasm0(ptr2, len2);
    } finally {
        wasm.__wbindgen_free(deferred3_0, deferred3_1, 1);
    }
}

/**
 * Derive a subkey using BLAKE2b KDF (libsodium compatible).
 *
 * Returns the derived subkey as base64.
 * @param {string} key_b64
 * @param {number} subkey_len
 * @param {bigint} subkey_id
 * @param {string} context
 * @returns {string}
 */
export function crypto_derive_subkey(key_b64, subkey_len, subkey_id, context) {
    let deferred4_0;
    let deferred4_1;
    try {
        const ptr0 = passStringToWasm0(key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(context, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.crypto_derive_subkey(ptr0, len0, subkey_len, subkey_id, ptr1, len1);
        var ptr3 = ret[0];
        var len3 = ret[1];
        if (ret[3]) {
            ptr3 = 0; len3 = 0;
            throw takeFromExternrefTable0(ret[2]);
        }
        deferred4_0 = ptr3;
        deferred4_1 = len3;
        return getStringFromWasm0(ptr3, len3);
    } finally {
        wasm.__wbindgen_free(deferred4_0, deferred4_1, 1);
    }
}

/**
 * Encrypt `data_b64` using SecretStream (single-message blob) with `key_b64`.
 * @param {string} data_b64
 * @param {string} key_b64
 * @returns {EncryptedBlob}
 */
export function crypto_encrypt_blob(data_b64, key_b64) {
    const ptr0 = passStringToWasm0(data_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ptr1 = passStringToWasm0(key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    const ret = wasm.crypto_encrypt_blob(ptr0, len0, ptr1, len1);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return EncryptedBlob.__wrap(ret[0]);
}

/**
 * Encrypt `data_b64` using SecretBox with `key_b64`.
 *
 * Returns ciphertext (`encrypted_data`) and nonce as base64.
 * @param {string} data_b64
 * @param {string} key_b64
 * @returns {EncryptedBox}
 */
export function crypto_encrypt_box(data_b64, key_b64) {
    const ptr0 = passStringToWasm0(data_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ptr1 = passStringToWasm0(key_b64, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    const ret = wasm.crypto_encrypt_box(ptr0, len0, ptr1, len1);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return EncryptedBox.__wrap(ret[0]);
}

/**
 * Generate a random 32-byte SecretBox key and return it as base64.
 * @returns {string}
 */
export function crypto_generate_key() {
    let deferred1_0;
    let deferred1_1;
    try {
        const ret = wasm.crypto_generate_key();
        deferred1_0 = ret[0];
        deferred1_1 = ret[1];
        return getStringFromWasm0(ret[0], ret[1]);
    } finally {
        wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
    }
}

/**
 * Generate a random X25519 keypair and return it as base64.
 * @returns {CryptoKeyPair}
 */
export function crypto_generate_keypair() {
    const ret = wasm.crypto_generate_keypair();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return CryptoKeyPair.__wrap(ret[0]);
}

/**
 * Generate a random 16-byte salt and return it as base64.
 * @returns {string}
 */
export function crypto_generate_salt() {
    let deferred1_0;
    let deferred1_1;
    try {
        const ret = wasm.crypto_generate_salt();
        deferred1_0 = ret[0];
        deferred1_1 = ret[1];
        return getStringFromWasm0(ret[0], ret[1]);
    } finally {
        wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
    }
}

/**
 * Generate a random 32-byte SecretStream key and return it as base64.
 * @returns {string}
 */
export function crypto_generate_stream_key() {
    let deferred1_0;
    let deferred1_1;
    try {
        const ret = wasm.crypto_generate_stream_key();
        deferred1_0 = ret[0];
        deferred1_1 = ret[1];
        return getStringFromWasm0(ret[0], ret[1]);
    } finally {
        wasm.__wbindgen_free(deferred1_0, deferred1_1, 1);
    }
}

/**
 * Initialize the crypto backend.
 *
 * This is a no-op for the pure-Rust implementation, but is provided for API
 * symmetry with other platforms.
 */
export function crypto_init() {
    const ret = wasm.crypto_init();
    if (ret[1]) {
        throw takeFromExternrefTable0(ret[0]);
    }
}

/**
 * Generate the download URL for a file.
 * @param {string} api_base_url
 * @param {bigint} file_id
 * @returns {string}
 */
export function file_download_url(api_base_url, file_id) {
    let deferred2_0;
    let deferred2_1;
    try {
        const ptr0 = passStringToWasm0(api_base_url, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.file_download_url(ptr0, len0, file_id);
        deferred2_0 = ret[0];
        deferred2_1 = ret[1];
        return getStringFromWasm0(ret[0], ret[1]);
    } finally {
        wasm.__wbindgen_free(deferred2_0, deferred2_1, 1);
    }
}
export function __wbg_Error_8c4e43fe74559d73(arg0, arg1) {
    const ret = Error(getStringFromWasm0(arg0, arg1));
    return ret;
}
export function __wbg_Number_04624de7d0e8332d(arg0) {
    const ret = Number(arg0);
    return ret;
}
export function __wbg_String_8f0eb39a4a4c2f66(arg0, arg1) {
    const ret = String(arg1);
    const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
}
export function __wbg___wbindgen_boolean_get_bbbb1c18aa2f5e25(arg0) {
    const v = arg0;
    const ret = typeof(v) === 'boolean' ? v : undefined;
    return isLikeNone(ret) ? 0xFFFFFF : ret ? 1 : 0;
}
export function __wbg___wbindgen_debug_string_0bc8482c6e3508ae(arg0, arg1) {
    const ret = debugString(arg1);
    const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
}
export function __wbg___wbindgen_in_47fa6863be6f2f25(arg0, arg1) {
    const ret = arg0 in arg1;
    return ret;
}
export function __wbg___wbindgen_is_function_0095a73b8b156f76(arg0) {
    const ret = typeof(arg0) === 'function';
    return ret;
}
export function __wbg___wbindgen_is_object_5ae8e5880f2c1fbd(arg0) {
    const val = arg0;
    const ret = typeof(val) === 'object' && val !== null;
    return ret;
}
export function __wbg___wbindgen_is_string_cd444516edc5b180(arg0) {
    const ret = typeof(arg0) === 'string';
    return ret;
}
export function __wbg___wbindgen_is_undefined_9e4d92534c42d778(arg0) {
    const ret = arg0 === undefined;
    return ret;
}
export function __wbg___wbindgen_jsval_loose_eq_9dd77d8cd6671811(arg0, arg1) {
    const ret = arg0 == arg1;
    return ret;
}
export function __wbg___wbindgen_number_get_8ff4255516ccad3e(arg0, arg1) {
    const obj = arg1;
    const ret = typeof(obj) === 'number' ? obj : undefined;
    getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
}
export function __wbg___wbindgen_string_get_72fb696202c56729(arg0, arg1) {
    const obj = arg1;
    const ret = typeof(obj) === 'string' ? obj : undefined;
    var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    var len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
}
export function __wbg___wbindgen_throw_be289d5034ed271b(arg0, arg1) {
    throw new Error(getStringFromWasm0(arg0, arg1));
}
export function __wbg__wbg_cb_unref_d9b87ff7982e3b21(arg0) {
    arg0._wbg_cb_unref();
}
export function __wbg_abort_2f0584e03e8e3950(arg0) {
    arg0.abort();
}
export function __wbg_abort_d549b92d3c665de1(arg0, arg1) {
    arg0.abort(arg1);
}
export function __wbg_append_a992ccc37aa62dc4() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
    arg0.append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
}, arguments); }
export function __wbg_autherror_new(arg0) {
    const ret = AuthError.__wrap(arg0);
    return ret;
}
export function __wbg_call_389efe28435a9388() { return handleError(function (arg0, arg1) {
    const ret = arg0.call(arg1);
    return ret;
}, arguments); }
export function __wbg_call_4708e0c13bdc8e95() { return handleError(function (arg0, arg1, arg2) {
    const ret = arg0.call(arg1, arg2);
    return ret;
}, arguments); }
export function __wbg_clearTimeout_42d9ccd50822fd3a(arg0) {
    const ret = clearTimeout(arg0);
    return ret;
}
export function __wbg_crypto_86f2631e91b51511(arg0) {
    const ret = arg0.crypto;
    return ret;
}
export function __wbg_cryptoerror_new(arg0) {
    const ret = CryptoError.__wrap(arg0);
    return ret;
}
export function __wbg_done_57b39ecd9addfe81(arg0) {
    const ret = arg0.done;
    return ret;
}
export function __wbg_fetch_6bbc32f991730587(arg0) {
    const ret = fetch(arg0);
    return ret;
}
export function __wbg_fetch_afb6a4b6cacf876d(arg0, arg1) {
    const ret = arg0.fetch(arg1);
    return ret;
}
export function __wbg_getRandomValues_b3f15fcbfabb0f8b() { return handleError(function (arg0, arg1) {
    arg0.getRandomValues(arg1);
}, arguments); }
export function __wbg_get_b3ed3ad4be2bc8ac() { return handleError(function (arg0, arg1) {
    const ret = Reflect.get(arg0, arg1);
    return ret;
}, arguments); }
export function __wbg_get_with_ref_key_1dc361bd10053bfe(arg0, arg1) {
    const ret = arg0[arg1];
    return ret;
}
export function __wbg_has_d4e53238966c12b6() { return handleError(function (arg0, arg1) {
    const ret = Reflect.has(arg0, arg1);
    return ret;
}, arguments); }
export function __wbg_headers_59a2938db9f80985(arg0) {
    const ret = arg0.headers;
    return ret;
}
export function __wbg_httperror_new(arg0) {
    const ret = HttpError.__wrap(arg0);
    return ret;
}
export function __wbg_instanceof_ArrayBuffer_c367199e2fa2aa04(arg0) {
    let result;
    try {
        result = arg0 instanceof ArrayBuffer;
    } catch (_) {
        result = false;
    }
    const ret = result;
    return ret;
}
export function __wbg_instanceof_Response_ee1d54d79ae41977(arg0) {
    let result;
    try {
        result = arg0 instanceof Response;
    } catch (_) {
        result = false;
    }
    const ret = result;
    return ret;
}
export function __wbg_instanceof_Uint8Array_9b9075935c74707c(arg0) {
    let result;
    try {
        result = arg0 instanceof Uint8Array;
    } catch (_) {
        result = false;
    }
    const ret = result;
    return ret;
}
export function __wbg_isSafeInteger_bfbc7332a9768d2a(arg0) {
    const ret = Number.isSafeInteger(arg0);
    return ret;
}
export function __wbg_iterator_6ff6560ca1568e55() {
    const ret = Symbol.iterator;
    return ret;
}
export function __wbg_length_32ed9a279acd054c(arg0) {
    const ret = arg0.length;
    return ret;
}
export function __wbg_msCrypto_d562bbe83e0d4b91(arg0) {
    const ret = arg0.msCrypto;
    return ret;
}
export function __wbg_new_361308b2356cecd0() {
    const ret = new Object();
    return ret;
}
export function __wbg_new_64284bd487f9d239() { return handleError(function () {
    const ret = new Headers();
    return ret;
}, arguments); }
export function __wbg_new_b5d9e2fb389fef91(arg0, arg1) {
    try {
        var state0 = {a: arg0, b: arg1};
        var cb0 = (arg0, arg1) => {
            const a = state0.a;
            state0.a = 0;
            try {
                return wasm_bindgen__convert__closures_____invoke__h3e9e0fbb5b6db788(a, state0.b, arg0, arg1);
            } finally {
                state0.a = a;
            }
        };
        const ret = new Promise(cb0);
        return ret;
    } finally {
        state0.a = state0.b = 0;
    }
}
export function __wbg_new_b949e7f56150a5d1() { return handleError(function () {
    const ret = new AbortController();
    return ret;
}, arguments); }
export function __wbg_new_dd2b680c8bf6ae29(arg0) {
    const ret = new Uint8Array(arg0);
    return ret;
}
export function __wbg_new_from_slice_a3d2629dc1826784(arg0, arg1) {
    const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
    return ret;
}
export function __wbg_new_no_args_1c7c842f08d00ebb(arg0, arg1) {
    const ret = new Function(getStringFromWasm0(arg0, arg1));
    return ret;
}
export function __wbg_new_with_length_a2c39cbe88fd8ff1(arg0) {
    const ret = new Uint8Array(arg0 >>> 0);
    return ret;
}
export function __wbg_new_with_str_and_init_a61cbc6bdef21614() { return handleError(function (arg0, arg1, arg2) {
    const ret = new Request(getStringFromWasm0(arg0, arg1), arg2);
    return ret;
}, arguments); }
export function __wbg_next_3482f54c49e8af19() { return handleError(function (arg0) {
    const ret = arg0.next();
    return ret;
}, arguments); }
export function __wbg_next_418f80d8f5303233(arg0) {
    const ret = arg0.next;
    return ret;
}
export function __wbg_node_e1f24f89a7336c2e(arg0) {
    const ret = arg0.node;
    return ret;
}
export function __wbg_process_3975fd6c72f520aa(arg0) {
    const ret = arg0.process;
    return ret;
}
export function __wbg_prototypesetcall_bdcdcc5842e4d77d(arg0, arg1, arg2) {
    Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), arg2);
}
export function __wbg_queueMicrotask_0aa0a927f78f5d98(arg0) {
    const ret = arg0.queueMicrotask;
    return ret;
}
export function __wbg_queueMicrotask_5bb536982f78a56f(arg0) {
    queueMicrotask(arg0);
}
export function __wbg_randomFillSync_f8c153b79f285817() { return handleError(function (arg0, arg1) {
    arg0.randomFillSync(arg1);
}, arguments); }
export function __wbg_require_b74f47fc2d022fd6() { return handleError(function () {
    const ret = module.require;
    return ret;
}, arguments); }
export function __wbg_resolve_002c4b7d9d8f6b64(arg0) {
    const ret = Promise.resolve(arg0);
    return ret;
}
export function __wbg_setTimeout_4ec014681668a581(arg0, arg1) {
    const ret = setTimeout(arg0, arg1);
    return ret;
}
export function __wbg_set_body_9a7e00afe3cfe244(arg0, arg1) {
    arg0.body = arg1;
}
export function __wbg_set_cache_315a3ed773a41543(arg0, arg1) {
    arg0.cache = __wbindgen_enum_RequestCache[arg1];
}
export function __wbg_set_credentials_c4a58d2e05ef24fb(arg0, arg1) {
    arg0.credentials = __wbindgen_enum_RequestCredentials[arg1];
}
export function __wbg_set_headers_cfc5f4b2c1f20549(arg0, arg1) {
    arg0.headers = arg1;
}
export function __wbg_set_method_c3e20375f5ae7fac(arg0, arg1, arg2) {
    arg0.method = getStringFromWasm0(arg1, arg2);
}
export function __wbg_set_mode_b13642c312648202(arg0, arg1) {
    arg0.mode = __wbindgen_enum_RequestMode[arg1];
}
export function __wbg_set_signal_f2d3f8599248896d(arg0, arg1) {
    arg0.signal = arg1;
}
export function __wbg_signal_d1285ecab4ebc5ad(arg0) {
    const ret = arg0.signal;
    return ret;
}
export function __wbg_static_accessor_GLOBAL_12837167ad935116() {
    const ret = typeof global === 'undefined' ? null : global;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
}
export function __wbg_static_accessor_GLOBAL_THIS_e628e89ab3b1c95f() {
    const ret = typeof globalThis === 'undefined' ? null : globalThis;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
}
export function __wbg_static_accessor_SELF_a621d3dfbb60d0ce() {
    const ret = typeof self === 'undefined' ? null : self;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
}
export function __wbg_static_accessor_WINDOW_f8727f0cf888e0bd() {
    const ret = typeof window === 'undefined' ? null : window;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
}
export function __wbg_status_89d7e803db911ee7(arg0) {
    const ret = arg0.status;
    return ret;
}
export function __wbg_stringify_8d1cc6ff383e8bae() { return handleError(function (arg0) {
    const ret = JSON.stringify(arg0);
    return ret;
}, arguments); }
export function __wbg_subarray_a96e1fef17ed23cb(arg0, arg1, arg2) {
    const ret = arg0.subarray(arg1 >>> 0, arg2 >>> 0);
    return ret;
}
export function __wbg_text_083b8727c990c8c0() { return handleError(function (arg0) {
    const ret = arg0.text();
    return ret;
}, arguments); }
export function __wbg_then_0d9fe2c7b1857d32(arg0, arg1, arg2) {
    const ret = arg0.then(arg1, arg2);
    return ret;
}
export function __wbg_then_b9e7b3b5f1a9e1b5(arg0, arg1) {
    const ret = arg0.then(arg1);
    return ret;
}
export function __wbg_url_c484c26b1fbf5126(arg0, arg1) {
    const ret = arg1.url;
    const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
}
export function __wbg_value_0546255b415e96c1(arg0) {
    const ret = arg0.value;
    return ret;
}
export function __wbg_versions_4e31226f5e8dc909(arg0) {
    const ret = arg0.versions;
    return ret;
}
export function __wbindgen_cast_0000000000000001(arg0, arg1) {
    // Cast intrinsic for `Closure(Closure { dtor_idx: 119, function: Function { arguments: [], shim_idx: 120, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
    const ret = makeMutClosure(arg0, arg1, wasm.wasm_bindgen__closure__destroy__hb43ea6df8e0e67c3, wasm_bindgen__convert__closures_____invoke__h3876b6b6d41d9be2);
    return ret;
}
export function __wbindgen_cast_0000000000000002(arg0, arg1) {
    // Cast intrinsic for `Closure(Closure { dtor_idx: 137, function: Function { arguments: [Externref], shim_idx: 138, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
    const ret = makeMutClosure(arg0, arg1, wasm.wasm_bindgen__closure__destroy__hdb1ecd681a512305, wasm_bindgen__convert__closures_____invoke__h609bb7d214b8ae29);
    return ret;
}
export function __wbindgen_cast_0000000000000003(arg0, arg1) {
    // Cast intrinsic for `Ref(Slice(U8)) -> NamedExternref("Uint8Array")`.
    const ret = getArrayU8FromWasm0(arg0, arg1);
    return ret;
}
export function __wbindgen_cast_0000000000000004(arg0, arg1) {
    // Cast intrinsic for `Ref(String) -> Externref`.
    const ret = getStringFromWasm0(arg0, arg1);
    return ret;
}
export function __wbindgen_init_externref_table() {
    const table = wasm.__wbindgen_externrefs;
    const offset = table.grow(4);
    table.set(0, undefined);
    table.set(offset + 0, undefined);
    table.set(offset + 1, null);
    table.set(offset + 2, true);
    table.set(offset + 3, false);
}
function wasm_bindgen__convert__closures_____invoke__h3876b6b6d41d9be2(arg0, arg1) {
    wasm.wasm_bindgen__convert__closures_____invoke__h3876b6b6d41d9be2(arg0, arg1);
}

function wasm_bindgen__convert__closures_____invoke__h609bb7d214b8ae29(arg0, arg1, arg2) {
    wasm.wasm_bindgen__convert__closures_____invoke__h609bb7d214b8ae29(arg0, arg1, arg2);
}

function wasm_bindgen__convert__closures_____invoke__h3e9e0fbb5b6db788(arg0, arg1, arg2, arg3) {
    wasm.wasm_bindgen__convert__closures_____invoke__h3e9e0fbb5b6db788(arg0, arg1, arg2, arg3);
}


const __wbindgen_enum_RequestCache = ["default", "no-store", "reload", "no-cache", "force-cache", "only-if-cached"];


const __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];


const __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];
const AuthErrorFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_autherror_free(ptr >>> 0, 1));
const CryptoErrorFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_cryptoerror_free(ptr >>> 0, 1));
const CryptoKeyPairFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_cryptokeypair_free(ptr >>> 0, 1));
const DecryptedKeysFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_decryptedkeys_free(ptr >>> 0, 1));
const DecryptedSecretsFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_decryptedsecrets_free(ptr >>> 0, 1));
const EncryptedBlobFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_encryptedblob_free(ptr >>> 0, 1));
const EncryptedBoxFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_encryptedbox_free(ptr >>> 0, 1));
const HttpClientFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_httpclient_free(ptr >>> 0, 1));
const HttpErrorFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_httperror_free(ptr >>> 0, 1));
const SrpCredentialsFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_srpcredentials_free(ptr >>> 0, 1));
const SrpSessionFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_srpsession_free(ptr >>> 0, 1));

function addToExternrefTable0(obj) {
    const idx = wasm.__externref_table_alloc();
    wasm.__wbindgen_externrefs.set(idx, obj);
    return idx;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => state.dtor(state.a, state.b));

function debugString(val) {
    // primitive types
    const type = typeof val;
    if (type == 'number' || type == 'boolean' || val == null) {
        return  `${val}`;
    }
    if (type == 'string') {
        return `"${val}"`;
    }
    if (type == 'symbol') {
        const description = val.description;
        if (description == null) {
            return 'Symbol';
        } else {
            return `Symbol(${description})`;
        }
    }
    if (type == 'function') {
        const name = val.name;
        if (typeof name == 'string' && name.length > 0) {
            return `Function(${name})`;
        } else {
            return 'Function';
        }
    }
    // objects
    if (Array.isArray(val)) {
        const length = val.length;
        let debug = '[';
        if (length > 0) {
            debug += debugString(val[0]);
        }
        for(let i = 1; i < length; i++) {
            debug += ', ' + debugString(val[i]);
        }
        debug += ']';
        return debug;
    }
    // Test for built-in
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
        className = builtInMatches[1];
    } else {
        // Failed to match the standard '[object ClassName]'
        return toString.call(val);
    }
    if (className == 'Object') {
        // we're a user defined class or Object
        // JSON.stringify avoids problems with cycles, and is generally much
        // easier than looping through ownProperties of `val`.
        try {
            return 'Object(' + JSON.stringify(val) + ')';
        } catch (_) {
            return 'Object';
        }
    }
    // errors
    if (val instanceof Error) {
        return `${val.name}: ${val.message}\n${val.stack}`;
    }
    // TODO we could test for more things here, like `Set`s and `Map`s.
    return className;
}

function getArrayU8FromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
}

let cachedDataViewMemory0 = null;
function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
        cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
}

function getStringFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return decodeText(ptr, len);
}

let cachedUint8ArrayMemory0 = null;
function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
        cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
}

function handleError(f, args) {
    try {
        return f.apply(this, args);
    } catch (e) {
        const idx = addToExternrefTable0(e);
        wasm.__wbindgen_exn_store(idx);
    }
}

function isLikeNone(x) {
    return x === undefined || x === null;
}

function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
    const real = (...args) => {

        // First up with a closure we increment the internal reference
        // count. This ensures that the Rust closure environment won't
        // be deallocated while we're invoking it.
        state.cnt++;
        const a = state.a;
        state.a = 0;
        try {
            return f(a, state.b, ...args);
        } finally {
            state.a = a;
            real._wbg_cb_unref();
        }
    };
    real._wbg_cb_unref = () => {
        if (--state.cnt === 0) {
            state.dtor(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
        }
    };
    CLOSURE_DTORS.register(real, state, state);
    return real;
}

function passStringToWasm0(arg, malloc, realloc) {
    if (realloc === undefined) {
        const buf = cachedTextEncoder.encode(arg);
        const ptr = malloc(buf.length, 1) >>> 0;
        getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr;
    }

    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;

    const mem = getUint8ArrayMemory0();

    let offset = 0;

    for (; offset < len; offset++) {
        const code = arg.charCodeAt(offset);
        if (code > 0x7F) break;
        mem[ptr + offset] = code;
    }
    if (offset !== len) {
        if (offset !== 0) {
            arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
        const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
        const ret = cachedTextEncoder.encodeInto(arg, view);

        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
    }

    WASM_VECTOR_LEN = offset;
    return ptr;
}

function takeFromExternrefTable0(idx) {
    const value = wasm.__wbindgen_externrefs.get(idx);
    wasm.__externref_table_dealloc(idx);
    return value;
}

let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
cachedTextDecoder.decode();
const MAX_SAFARI_DECODE_BYTES = 2146435072;
let numBytesDecoded = 0;
function decodeText(ptr, len) {
    numBytesDecoded += len;
    if (numBytesDecoded >= MAX_SAFARI_DECODE_BYTES) {
        cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
        cachedTextDecoder.decode();
        numBytesDecoded = len;
    }
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
}

const cachedTextEncoder = new TextEncoder();

if (!('encodeInto' in cachedTextEncoder)) {
    cachedTextEncoder.encodeInto = function (arg, view) {
        const buf = cachedTextEncoder.encode(arg);
        view.set(buf);
        return {
            read: arg.length,
            written: buf.length
        };
    };
}

let WASM_VECTOR_LEN = 0;


let wasm;
export function __wbg_set_wasm(val) {
    wasm = val;
}
