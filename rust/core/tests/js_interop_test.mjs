/**
 * JavaScript crypto tests for ente-core compatibility.
 * 
 * Since JS libsodium-wrappers IS libsodium, and we've validated Rust matches
 * libsodium, these tests verify:
 * 1. JS crypto works correctly (roundtrips)
 * 2. Constants match Rust expectations
 * 3. Format/sizes match what Rust expects
 * 4. Ente workflow works end-to-end
 *
 * Run with: node tests/js_interop_test.mjs
 */

import _sodium from 'libsodium-wrappers-sumo';

async function runTests() {
    await _sodium.ready;
    const sodium = _sodium;

    console.log('╔════════════════════════════════════════════════════════════════╗');
    console.log('║     JavaScript Crypto Validation Tests                          ║');
    console.log('╚════════════════════════════════════════════════════════════════╝\n');

    let passed = 0;
    let failed = 0;

    function test(name, fn) {
        try {
            fn();
            console.log(`  ✓ ${name}`);
            passed++;
        } catch (e) {
            console.log(`  ✗ ${name}`);
            console.log(`    Error: ${e.message}`);
            failed++;
        }
    }

    function assertEqual(actual, expected, msg = '') {
        const actualStr = typeof actual === 'string' ? actual :
            actual instanceof Uint8Array ? sodium.to_hex(actual) :
                JSON.stringify(actual);
        const expectedStr = typeof expected === 'string' ? expected :
            expected instanceof Uint8Array ? sodium.to_hex(expected) :
                JSON.stringify(expected);
        if (actualStr !== expectedStr) {
            throw new Error(`${msg}\n    Expected: ${expectedStr}\n    Actual: ${actualStr}`);
        }
    }

    // =========================================================================
    // CONSTANTS: Verify values match Rust
    // =========================================================================

    console.log('── Constants Verification ──\n');

    test('SecretBox constants', () => {
        assertEqual(sodium.crypto_secretbox_KEYBYTES, 32);
        assertEqual(sodium.crypto_secretbox_NONCEBYTES, 24);
        assertEqual(sodium.crypto_secretbox_MACBYTES, 16);
    });

    test('SecretStream constants', () => {
        assertEqual(sodium.crypto_secretstream_xchacha20poly1305_KEYBYTES, 32);
        assertEqual(sodium.crypto_secretstream_xchacha20poly1305_HEADERBYTES, 24);
        assertEqual(sodium.crypto_secretstream_xchacha20poly1305_ABYTES, 17);
        assertEqual(sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL, 3);
        assertEqual(sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE, 0);
    });

    test('Argon2 constants', () => {
        assertEqual(sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE, 67108864); // 64 MB
        assertEqual(sodium.crypto_pwhash_MEMLIMIT_MODERATE, 268435456); // 256 MB
        assertEqual(sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE, 2);
        assertEqual(sodium.crypto_pwhash_OPSLIMIT_MODERATE, 3);
        assertEqual(sodium.crypto_pwhash_SALTBYTES, 16);
    });

    test('KDF constants', () => {
        assertEqual(sodium.crypto_kdf_KEYBYTES, 32);
        assertEqual(sodium.crypto_kdf_CONTEXTBYTES, 8);
        assertEqual(sodium.crypto_kdf_BYTES_MIN, 16);
        assertEqual(sodium.crypto_kdf_BYTES_MAX, 64);
    });

    test('Sealed box constants', () => {
        assertEqual(sodium.crypto_box_PUBLICKEYBYTES, 32);
        assertEqual(sodium.crypto_box_SECRETKEYBYTES, 32);
        assertEqual(sodium.crypto_box_SEALBYTES, 48);
    });

    test('Hash constants', () => {
        assertEqual(sodium.crypto_generichash_BYTES, 32);
        assertEqual(sodium.crypto_generichash_BYTES_MIN, 16);
        assertEqual(sodium.crypto_generichash_BYTES_MAX, 64);
    });

    // =========================================================================
    // ROUNDTRIP: Verify each primitive works
    // =========================================================================

    console.log('\n── Roundtrip Tests ──\n');

    test('SecretBox roundtrip', () => {
        const key = sodium.crypto_secretbox_keygen();
        const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
        const plaintext = sodium.from_string('Test message for SecretBox');

        const ciphertext = sodium.crypto_secretbox_easy(plaintext, nonce, key);
        assertEqual(ciphertext.length, plaintext.length + 16, 'Ciphertext size');

        const decrypted = sodium.crypto_secretbox_open_easy(ciphertext, nonce, key);
        assertEqual(sodium.to_string(decrypted), 'Test message for SecretBox');
    });

    test('SecretStream roundtrip', () => {
        const key = sodium.crypto_secretstream_xchacha20poly1305_keygen();
        const plaintext = sodium.from_string('Test message for SecretStream');

        const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
        assertEqual(header.length, 24, 'Header size');

        const ciphertext = sodium.crypto_secretstream_xchacha20poly1305_push(
            encState, plaintext, null, sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
        );
        assertEqual(ciphertext.length, plaintext.length + 17, 'Ciphertext size');

        const decState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
        const { message, tag } = sodium.crypto_secretstream_xchacha20poly1305_pull(decState, ciphertext);
        assertEqual(sodium.to_string(message), 'Test message for SecretStream');
        assertEqual(tag, sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL);
    });

    test('SecretStream multi-chunk roundtrip', () => {
        const key = sodium.crypto_secretstream_xchacha20poly1305_keygen();
        const chunks = ['First chunk', 'Second chunk', 'Third chunk'];

        const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
        const encrypted = chunks.map((chunk, i) => {
            const tag = i === chunks.length - 1 
                ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL 
                : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
            return sodium.crypto_secretstream_xchacha20poly1305_push(
                encState, sodium.from_string(chunk), null, tag
            );
        });

        const decState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
        encrypted.forEach((ct, i) => {
            const { message, tag } = sodium.crypto_secretstream_xchacha20poly1305_pull(decState, ct);
            assertEqual(sodium.to_string(message), chunks[i]);
            const expectedTag = i === chunks.length - 1 
                ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL 
                : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
            assertEqual(tag, expectedTag);
        });
    });

    test('Sealed box roundtrip', () => {
        const { publicKey, privateKey } = sodium.crypto_box_keypair();
        const plaintext = sodium.from_string('Sealed box message');

        assertEqual(publicKey.length, 32, 'Public key size');
        assertEqual(privateKey.length, 32, 'Private key size');

        const ciphertext = sodium.crypto_box_seal(plaintext, publicKey);
        assertEqual(ciphertext.length, plaintext.length + 48, 'Ciphertext size');

        const decrypted = sodium.crypto_box_seal_open(ciphertext, publicKey, privateKey);
        assertEqual(sodium.to_string(decrypted), 'Sealed box message');
    });

    test('Argon2 deterministic derivation', () => {
        const password = sodium.from_string('test_password');
        const salt = sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES);

        const key1 = sodium.crypto_pwhash(
            32, password, salt,
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_ARGON2ID13
        );

        const key2 = sodium.crypto_pwhash(
            32, password, salt,
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_ARGON2ID13
        );

        assertEqual(key1, key2, 'Same inputs produce same key');
        assertEqual(key1.length, 32, 'Key size');
    });

    test('KDF deterministic subkey derivation', () => {
        const masterKey = sodium.crypto_kdf_keygen();

        const subKey1 = sodium.crypto_kdf_derive_from_key(32, 1, 'loginctx', masterKey);
        const subKey2 = sodium.crypto_kdf_derive_from_key(32, 1, 'loginctx', masterKey);
        const subKey3 = sodium.crypto_kdf_derive_from_key(32, 2, 'loginctx', masterKey);

        assertEqual(subKey1, subKey2, 'Same inputs produce same subkey');
        assertEqual(subKey1.length, 32, 'Subkey size');
        
        // Different ID should produce different key
        if (sodium.to_hex(subKey1) === sodium.to_hex(subKey3)) {
            throw new Error('Different IDs should produce different subkeys');
        }
    });

    test('BLAKE2b hash', () => {
        const data = sodium.from_string('Data to hash');

        const hash32 = sodium.crypto_generichash(32, data);
        const hash64 = sodium.crypto_generichash(64, data);

        assertEqual(hash32.length, 32, 'Hash32 size');
        assertEqual(hash64.length, 64, 'Hash64 size');

        // Same input produces same hash
        const hash32_2 = sodium.crypto_generichash(32, data);
        assertEqual(hash32, hash32_2, 'Deterministic hash');
    });

    // =========================================================================
    // ENTE WORKFLOW: Full encryption flow
    // =========================================================================

    console.log('\n── Ente Workflow Simulation ──\n');

    test('Full key hierarchy encryption', () => {
        // 1. Derive KEK from password
        const password = sodium.from_string('user_password');
        const salt = sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES);
        const kek = sodium.crypto_pwhash(
            32, password, salt,
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_ARGON2ID13
        );

        // 2. Generate and encrypt master key
        const masterKey = sodium.crypto_secretbox_keygen();
        const masterKeyNonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
        const encryptedMasterKey = sodium.crypto_secretbox_easy(masterKey, masterKeyNonce, kek);

        // 3. Decrypt and verify
        const decryptedMasterKey = sodium.crypto_secretbox_open_easy(encryptedMasterKey, masterKeyNonce, kek);
        assertEqual(decryptedMasterKey, masterKey);
    });

    test('Login key derivation', () => {
        const masterKey = sodium.crypto_kdf_keygen();
        
        // Derive login key using same method as Rust
        const subKey = sodium.crypto_kdf_derive_from_key(32, 1, 'loginctx', masterKey);
        const loginKey = subKey.slice(0, 16);

        assertEqual(loginKey.length, 16, 'Login key is 16 bytes');
    });

    test('File encryption workflow', () => {
        // Generate file key
        const fileKey = sodium.crypto_secretstream_xchacha20poly1305_keygen();

        // Encrypt file content
        const fileContent = sodium.from_string('Photo EXIF data and pixels...');
        const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(fileKey);
        const encryptedFile = sodium.crypto_secretstream_xchacha20poly1305_push(
            encState, fileContent, null, sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
        );

        // Encrypt metadata
        const metadata = JSON.stringify({ title: 'photo.jpg', size: 1234 });
        const { state: metaState, header: metaHeader } = sodium.crypto_secretstream_xchacha20poly1305_init_push(fileKey);
        const encryptedMeta = sodium.crypto_secretstream_xchacha20poly1305_push(
            metaState, sodium.from_string(metadata), null, sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
        );

        // Decrypt and verify
        const decState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, fileKey);
        const { message: decFile } = sodium.crypto_secretstream_xchacha20poly1305_pull(decState, encryptedFile);
        assertEqual(sodium.to_string(decFile), 'Photo EXIF data and pixels...');

        const metaDecState = sodium.crypto_secretstream_xchacha20poly1305_init_pull(metaHeader, fileKey);
        const { message: decMeta } = sodium.crypto_secretstream_xchacha20poly1305_pull(metaDecState, encryptedMeta);
        const parsedMeta = JSON.parse(sodium.to_string(decMeta));
        assertEqual(parsedMeta.title, 'photo.jpg');
    });

    test('Recovery key encryption', () => {
        const masterKey = sodium.crypto_secretbox_keygen();
        const recoveryKey = sodium.crypto_secretbox_keygen();

        // Encrypt master key with recovery key
        const nonce = sodium.randombytes_buf(sodium.crypto_secretbox_NONCEBYTES);
        const encryptedMasterKey = sodium.crypto_secretbox_easy(masterKey, nonce, recoveryKey);

        // Decrypt with recovery key
        const decryptedMasterKey = sodium.crypto_secretbox_open_easy(encryptedMasterKey, nonce, recoveryKey);
        assertEqual(decryptedMasterKey, masterKey);
    });

    // =========================================================================
    // SUMMARY
    // =========================================================================

    console.log('\n╔════════════════════════════════════════════════════════════════╗');
    console.log(`║  Results: ${passed} passed, ${failed} failed${' '.repeat(Math.max(0, 35 - String(passed).length - String(failed).length))}║`);
    console.log('╚════════════════════════════════════════════════════════════════╝');

    if (failed > 0) {
        process.exit(1);
    }
}

runTests().catch(e => {
    console.error('Test runner failed:', e);
    process.exit(1);
});
