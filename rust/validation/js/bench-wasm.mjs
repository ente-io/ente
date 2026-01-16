import fs from 'node:fs';
import { webcrypto } from 'node:crypto';
import { createRequire } from 'node:module';

if (!globalThis.crypto) {
  globalThis.crypto = webcrypto;
}

const require = createRequire(import.meta.url);
const _sodium = require('libsodium-wrappers-sumo');
const wasm = require('../wasm/pkg/ente_validation_wasm.js');

const KB = 1024;
const MB = 1024 * 1024;
const STREAM_CHUNK = 64 * 1024;

const ARGON_MEM = 67_108_864; // 64 MiB
const ARGON_OPS = 2;
const AUTH_TOKEN = new TextEncoder().encode('benchmark-auth-token');

function nowNs() {
  return process.hrtime.bigint();
}

function elapsedMs(startNs) {
  const diff = process.hrtime.bigint() - startNs;
  return Number(diff) / 1e6;
}

function formatSize(bytes) {
  if (bytes === 0) {
    return 'n/a';
  }
  return `${(bytes / MB).toFixed(1)}MiB`;
}

function rate(bytes, iterations, durationMs) {
  const seconds = durationMs / 1000.0;
  if (bytes === 0) {
    return { label: 'ops/s', value: iterations / seconds };
  }
  const mib = bytes / MB;
  return { label: 'MiB/s', value: (mib * iterations) / seconds };
}

function printHeader() {
  console.log('Impl        | Case        | Op      | Size     | Iters | ms/op     | Rate');
  console.log('------------+-------------+---------+----------+-------+-----------+------------');
}

function printRow(row) {
  const size = formatSize(row.sizeBytes);
  const msPerOp = row.durationMs / row.iterations;
  const { label, value } = rate(row.sizeBytes, row.iterations, row.durationMs);

  const line = `${row.impl.padEnd(11)} | ${row.case.padEnd(11)} | ${row.op.padEnd(7)} | ${size
    .toString()
    .padStart(8)} | ${row.iterations
    .toString()
    .padStart(5)} | ${msPerOp.toFixed(3).padStart(9)} ms/op | ${label} ${value
    .toFixed(2)
    .padStart(8)}`;
  console.log(line);
}

function printSummary(results) {
  const groups = new Map();

  for (const row of results) {
    const key = `${row.case}|${row.op}|${row.sizeBytes}`;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(row);
  }

  console.log('\nWinner Summary (lower ms/op wins)');

  const keys = [...groups.keys()].sort();
  for (const key of keys) {
    const [caseName, op, sizeText] = key.split('|');
    const sizeBytes = Number(sizeText);
    const rows = groups
      .get(key)
      .slice()
      .sort((a, b) => a.durationMs / a.iterations - b.durationMs / b.iterations);

    const sizeLabel = formatSize(sizeBytes);

    if (rows.length === 1) {
      console.log(`- ${caseName} ${op} ${sizeLabel}: ${rows[0].impl} only`);
      continue;
    }

    const best = rows[0];
    const runner = rows[1];
    const bestMs = best.durationMs / best.iterations;
    const runnerMs = runner.durationMs / runner.iterations;
    const percent = runnerMs > 0 ? ((runnerMs - bestMs) / runnerMs) * 100 : 0;

    console.log(`- ${caseName} ${op} ${sizeLabel}: ${best.impl} by ${percent.toFixed(1)}%`);
  }
}

function writeJsonIfRequested(results) {
  const path = process.env.BENCH_JSON;
  if (!path) {
    return;
  }

  const payload = { results };
  fs.writeFileSync(path, JSON.stringify(payload, null, 2));
}

function initPullState(sodium, header, key) {
  const result = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
  if (result && typeof result === 'object' && 'state' in result) {
    return result.state;
  }
  return result;
}

function chunkCount(length) {
  return Math.ceil(length / STREAM_CHUNK);
}

function bench(iterations, fn) {
  const start = nowNs();
  for (let i = 0; i < iterations; i += 1) {
    fn();
  }
  return elapsedMs(start);
}

function toB64(sodium, bytes) {
  return sodium.to_base64(bytes, sodium.base64_variants.ORIGINAL);
}

function fromB64(sodium, text) {
  return sodium.from_base64(text, sodium.base64_variants.ORIGINAL);
}

function jsAuthSignup(sodium, password) {
  const masterKey = sodium.randombytes_buf(32);
  const recoveryKey = sodium.randombytes_buf(32);

  const nonceMasterRecovery = sodium.randombytes_buf(24);
  const encMasterWithRecovery = sodium.crypto_secretbox_easy(
    masterKey,
    nonceMasterRecovery,
    recoveryKey
  );

  const nonceRecoveryMaster = sodium.randombytes_buf(24);
  const encRecoveryWithMaster = sodium.crypto_secretbox_easy(
    recoveryKey,
    nonceRecoveryMaster,
    masterKey
  );

  const kekSalt = sodium.randombytes_buf(16);
  const kek = sodium.crypto_pwhash(
    32,
    password,
    kekSalt,
    ARGON_OPS,
    ARGON_MEM,
    sodium.crypto_pwhash_ALG_ARGON2ID13
  );
  const loginKey = sodium.crypto_kdf_derive_from_key(16, 1, 'loginctx', kek);

  const keyNonce = sodium.randombytes_buf(24);
  const encKey = sodium.crypto_secretbox_easy(masterKey, keyNonce, kek);

  const { publicKey, privateKey } = sodium.crypto_box_keypair();
  const secretKeyNonce = sodium.randombytes_buf(24);
  const encSecretKey = sodium.crypto_secretbox_easy(privateKey, secretKeyNonce, masterKey);

  const keyAttrs = {
    kek_salt: toB64(sodium, kekSalt),
    encrypted_key: toB64(sodium, encKey),
    key_decryption_nonce: toB64(sodium, keyNonce),
    public_key: toB64(sodium, publicKey),
    encrypted_secret_key: toB64(sodium, encSecretKey),
    secret_key_decryption_nonce: toB64(sodium, secretKeyNonce),
    mem_limit: ARGON_MEM,
    ops_limit: ARGON_OPS,
    master_key_encrypted_with_recovery_key: toB64(sodium, encMasterWithRecovery),
    master_key_decryption_nonce: toB64(sodium, nonceMasterRecovery),
    recovery_key_encrypted_with_master_key: toB64(sodium, encRecoveryWithMaster),
    recovery_key_decryption_nonce: toB64(sodium, nonceRecoveryMaster),
  };

  return { keyAttrs, loginKey, publicKey };
}

function jsAuthBuildArtifacts(sodium, password) {
  const { keyAttrs, publicKey } = jsAuthSignup(sodium, password);
  const encryptedToken = toB64(sodium, sodium.crypto_box_seal(AUTH_TOKEN, publicKey));
  return { keyAttrs, encryptedToken };
}

function jsAuthLogin(sodium, password, keyAttrs, encryptedToken) {
  const kekSalt = fromB64(sodium, keyAttrs.kek_salt);
  const kek = sodium.crypto_pwhash(
    32,
    password,
    kekSalt,
    keyAttrs.ops_limit ?? ARGON_OPS,
    keyAttrs.mem_limit ?? ARGON_MEM,
    sodium.crypto_pwhash_ALG_ARGON2ID13
  );

  const encKey = fromB64(sodium, keyAttrs.encrypted_key);
  const keyNonce = fromB64(sodium, keyAttrs.key_decryption_nonce);
  const masterKey = sodium.crypto_secretbox_open_easy(encKey, keyNonce, kek);

  const encSecretKey = fromB64(sodium, keyAttrs.encrypted_secret_key);
  const secretKeyNonce = fromB64(sodium, keyAttrs.secret_key_decryption_nonce);
  const secretKey = sodium.crypto_secretbox_open_easy(encSecretKey, secretKeyNonce, masterKey);

  const publicKey = fromB64(sodium, keyAttrs.public_key);
  const sealedToken = fromB64(sodium, encryptedToken);
  const token = sodium.crypto_box_seal_open(sealedToken, publicKey, secretKey);
  return token;
}

async function run() {
  await _sodium.ready;
  const sodium = _sodium;

  console.log('==============================================================');
  console.log('WASM benchmark (rust-core vs libsodium-wrappers)');
  console.log('==============================================================\n');

  const results = [];

  // SecretBox (1 MiB)
  const secretboxData = new Uint8Array(MB).fill(0x2a);
  const secretboxKey = new Uint8Array(32).fill(0x11);
  const secretboxNonce = new Uint8Array(24).fill(0x22);
  const secretboxIters = 50;

  results.push({
    impl: 'rust-wasm',
    case: 'secretbox',
    op: 'encrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const ciphertext = wasm.secretbox_encrypt(secretboxData, secretboxNonce, secretboxKey);
      return ciphertext[0];
    }),
  });

  results.push({
    impl: 'js-wasm',
    case: 'secretbox',
    op: 'encrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const ciphertext = sodium.crypto_secretbox_easy(
        secretboxData,
        secretboxNonce,
        secretboxKey
      );
      return ciphertext[0];
    }),
  });

  const rustSecretboxCiphertext = wasm.secretbox_encrypt(
    secretboxData,
    secretboxNonce,
    secretboxKey
  );
  const jsSecretboxCiphertext = sodium.crypto_secretbox_easy(
    secretboxData,
    secretboxNonce,
    secretboxKey
  );

  results.push({
    impl: 'rust-wasm',
    case: 'secretbox',
    op: 'decrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const plaintext = wasm.secretbox_decrypt(
        rustSecretboxCiphertext,
        secretboxNonce,
        secretboxKey
      );
      return plaintext[0];
    }),
  });

  results.push({
    impl: 'js-wasm',
    case: 'secretbox',
    op: 'decrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const plaintext = sodium.crypto_secretbox_open_easy(
        jsSecretboxCiphertext,
        secretboxNonce,
        secretboxKey
      );
      return plaintext[0];
    }),
  });

  // Stream (1 MiB, 50 MiB)
  for (const size of [1 * MB, 50 * MB]) {
    const data = new Uint8Array(size).fill(0x5a);
    const key = new Uint8Array(32).fill(0x33);
    const iterations = size >= 50 * MB ? 3 : 10;
    const chunks = chunkCount(data.length);

    results.push({
      impl: 'rust-wasm',
      case: 'stream',
      op: 'encrypt',
      sizeBytes: data.length,
      iterations,
      durationMs: bench(iterations, () => {
        const encryptor = new wasm.StreamEncryptor(key);
        const header = encryptor.header;
        let offset = 0;
        for (let index = 0; index < chunks; index += 1) {
          const end = Math.min(offset + STREAM_CHUNK, data.length);
          const chunk = data.subarray(offset, end);
          const isFinal = index + 1 === chunks;
          const ciphertext = encryptor.push(chunk, isFinal);
          offset = end;
          if (ciphertext[0] === 255) {
            return 1;
          }
        }
        if (header[0] === 255) {
          return 1;
        }
        return 0;
      }),
    });

    results.push({
      impl: 'js-wasm',
      case: 'stream',
      op: 'encrypt',
      sizeBytes: data.length,
      iterations,
      durationMs: bench(iterations, () => {
        const { state } = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
        let offset = 0;
        for (let index = 0; index < chunks; index += 1) {
          const end = Math.min(offset + STREAM_CHUNK, data.length);
          const chunk = data.subarray(offset, end);
          const tag =
            index + 1 === chunks
              ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
              : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
          const ciphertext = sodium.crypto_secretstream_xchacha20poly1305_push(
            state,
            chunk,
            null,
            tag
          );
          offset = end;
          if (ciphertext[0] === 255) {
            return 1;
          }
        }
        return 0;
      }),
    });

    const rustEnc = new wasm.StreamEncryptor(key);
    const rustHeader = rustEnc.header;
    const rustCipherChunks = [];
    let rustOffset = 0;
    for (let index = 0; index < chunks; index += 1) {
      const end = Math.min(rustOffset + STREAM_CHUNK, data.length);
      const chunk = data.subarray(rustOffset, end);
      const isFinal = index + 1 === chunks;
      rustCipherChunks.push(rustEnc.push(chunk, isFinal));
      rustOffset = end;
    }

    const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
    const jsCipherChunks = [];
    let jsOffset = 0;
    for (let index = 0; index < chunks; index += 1) {
      const end = Math.min(jsOffset + STREAM_CHUNK, data.length);
      const chunk = data.subarray(jsOffset, end);
      const tag =
        index + 1 === chunks
          ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
          : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
      jsCipherChunks.push(
        sodium.crypto_secretstream_xchacha20poly1305_push(encState, chunk, null, tag)
      );
      jsOffset = end;
    }

    results.push({
      impl: 'rust-wasm',
      case: 'stream',
      op: 'decrypt',
      sizeBytes: data.length,
      iterations,
      durationMs: bench(iterations, () => {
        const decryptor = new wasm.StreamDecryptor(rustHeader, key);
        for (const chunk of rustCipherChunks) {
          const plaintext = decryptor.pull(chunk);
          if (plaintext[0] === 255) {
            return 1;
          }
        }
        return 0;
      }),
    });

    results.push({
      impl: 'js-wasm',
      case: 'stream',
      op: 'decrypt',
      sizeBytes: data.length,
      iterations,
      durationMs: bench(iterations, () => {
        const decState = initPullState(sodium, header, key);
        for (const chunk of jsCipherChunks) {
          const { message } = sodium.crypto_secretstream_xchacha20poly1305_pull(decState, chunk);
          if (message[0] === 255) {
            return 1;
          }
        }
        return 0;
      }),
    });
  }

  // Argon2id (interactive params)
  const argonIters = 3;
  const argonSalt = new Uint8Array(sodium.crypto_pwhash_SALTBYTES).fill(0x7b);

  results.push({
    impl: 'rust-wasm',
    case: 'argon2id',
    op: 'derive',
    sizeBytes: 0,
    iterations: argonIters,
    durationMs: bench(argonIters, () => {
      const key = wasm.argon2_derive('benchmark-password', argonSalt, ARGON_MEM, ARGON_OPS);
      return key[0];
    }),
  });

  results.push({
    impl: 'js-wasm',
    case: 'argon2id',
    op: 'derive',
    sizeBytes: 0,
    iterations: argonIters,
    durationMs: bench(argonIters, () => {
      const key = sodium.crypto_pwhash(
        32,
        'benchmark-password',
        argonSalt,
        ARGON_OPS,
        ARGON_MEM,
        sodium.crypto_pwhash_ALG_ARGON2ID13
      );
      return key[0];
    }),
  });

  // Auth flow (signup + login)
  const authIters = 3;
  const authPassword = 'benchmark-password';

  results.push({
    impl: 'rust-wasm',
    case: 'auth',
    op: 'signup',
    sizeBytes: 0,
    iterations: authIters,
    durationMs: bench(authIters, () => {
      const loginKey = wasm.auth_signup(authPassword);
      return loginKey[0];
    }),
  });

  results.push({
    impl: 'js-wasm',
    case: 'auth',
    op: 'signup',
    sizeBytes: 0,
    iterations: authIters,
    durationMs: bench(authIters, () => {
      const { loginKey } = jsAuthSignup(sodium, authPassword);
      return loginKey[0];
    }),
  });

  const rustAuthArtifacts = wasm.auth_build_artifacts(authPassword);
  const jsAuthArtifacts = jsAuthBuildArtifacts(sodium, authPassword);

  results.push({
    impl: 'rust-wasm',
    case: 'auth',
    op: 'login',
    sizeBytes: 0,
    iterations: authIters,
    durationMs: bench(authIters, () => {
      const masterKey = wasm.auth_login(
        authPassword,
        rustAuthArtifacts.key_attrs_json,
        rustAuthArtifacts.encrypted_token
      );
      return masterKey[0];
    }),
  });

  results.push({
    impl: 'js-wasm',
    case: 'auth',
    op: 'login',
    sizeBytes: 0,
    iterations: authIters,
    durationMs: bench(authIters, () => {
      const token = jsAuthLogin(
        sodium,
        authPassword,
        jsAuthArtifacts.keyAttrs,
        jsAuthArtifacts.encryptedToken
      );
      return token[0];
    }),
  });

  printHeader();
  for (const row of results) {
    printRow(row);
  }
  printSummary(results);
  writeJsonIfRequested(results);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
