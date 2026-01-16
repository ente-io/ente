import init, * as wasm from '../wasm/pkg/ente_validation_wasm.js';
import sodiumModule from 'https://cdn.jsdelivr.net/npm/libsodium-wrappers-sumo@0.7.15/+esm';

const KB = 1024;
const MB = 1024 * 1024;
const STREAM_CHUNK = 64 * KB;

const ARGON_MEM = 67_108_864; // 64 MiB
const ARGON_OPS = 2;
const AUTH_TOKEN = new TextEncoder().encode('benchmark-auth-token');

let wasmReadyPromise;

function nowMs() {
  return performance.now();
}

function elapsedMs(startMs) {
  return performance.now() - startMs;
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

function clearResults() {
  const resultsEl = document.getElementById('results');
  resultsEl.innerHTML = '';
}

function setStatus(text) {
  const statusEl = document.getElementById('status');
  statusEl.textContent = text;
}

function renderResults(results, meta) {
  const resultsEl = document.getElementById('results');
  resultsEl.innerHTML = '';

  if (meta) {
    const metaLine = document.createElement('p');
    metaLine.textContent = `Warmup: ${meta.warmupIterations} | Iteration scale: ${meta.iterScale} | ` +
      `Rust WASM: ${meta.runRust ? 'on' : 'off'} | JS WASM: ${meta.runJs ? 'on' : 'off'}`;
    resultsEl.appendChild(metaLine);
  }

  const table = document.createElement('table');
  const head = document.createElement('thead');
  head.innerHTML = `
    <tr>
      <th>Impl</th>
      <th>Case</th>
      <th>Op</th>
      <th>Size</th>
      <th>Iters</th>
      <th>ms/op</th>
      <th>Rate</th>
    </tr>
  `;
  table.appendChild(head);

  const body = document.createElement('tbody');
  for (const row of results) {
    const size = formatSize(row.sizeBytes);
    const msPerOp = row.durationMs / row.iterations;
    const { label, value } = rate(row.sizeBytes, row.iterations, row.durationMs);

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${row.impl}</td>
      <td>${row.case}</td>
      <td>${row.op}</td>
      <td>${size}</td>
      <td>${row.iterations}</td>
      <td>${msPerOp.toFixed(3)}</td>
      <td>${label} ${value.toFixed(2)}</td>
    `;
    body.appendChild(tr);
  }
  table.appendChild(body);
  resultsEl.appendChild(table);

  const summary = document.createElement('div');
  summary.className = 'summary';
  const summaryTitle = document.createElement('strong');
  summaryTitle.textContent = 'Winner Summary (lower ms/op wins)';
  summary.appendChild(summaryTitle);

  const list = document.createElement('ul');
  const groups = new Map();
  for (const row of results) {
    const key = `${row.case}|${row.op}|${row.sizeBytes}`;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(row);
  }

  const keys = [...groups.keys()].sort();
  for (const key of keys) {
    const [caseName, op, sizeText] = key.split('|');
    const sizeBytes = Number(sizeText);
    const rows = groups
      .get(key)
      .slice()
      .sort((a, b) => a.durationMs / a.iterations - b.durationMs / b.iterations);

    const sizeLabel = formatSize(sizeBytes);
    const li = document.createElement('li');

    if (rows.length === 1) {
      li.textContent = `${caseName} ${op} ${sizeLabel}: ${rows[0].impl} only`;
    } else {
      const best = rows[0];
      const runner = rows[1];
      const bestMs = best.durationMs / best.iterations;
      const runnerMs = runner.durationMs / runner.iterations;
      const percent = runnerMs > 0 ? ((runnerMs - bestMs) / runnerMs) * 100 : 0;
      li.textContent = `${caseName} ${op} ${sizeLabel}: ${best.impl} by ${percent.toFixed(1)}%`;
    }

    list.appendChild(li);
  }

  summary.appendChild(list);
  resultsEl.appendChild(summary);
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

function bench(iterations, warmupIterations, fn) {
  for (let i = 0; i < warmupIterations; i += 1) {
    fn();
  }

  const start = nowMs();
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

async function getWasm() {
  if (!wasmReadyPromise) {
    wasmReadyPromise = init();
  }
  await wasmReadyPromise;
  return wasm;
}

function parsePositiveInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

function parseNonNegativeInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return fallback;
  }
  return parsed;
}

async function runBench() {
  const runRust = document.getElementById('run-rust').checked;
  const runJs = document.getElementById('run-js').checked;
  const warmupIterations = parseNonNegativeInt(
    document.getElementById('warmup-iters').value,
    1
  );
  const iterScale = parsePositiveInt(document.getElementById('iter-scale').value, 1);

  if (!runRust && !runJs) {
    window.alert('Select at least one implementation to run.');
    return;
  }

  clearResults();
  setStatus('Running...');

  if (runJs) {
    await sodiumModule.ready;
  }

  const wasmApi = runRust ? await getWasm() : null;
  const sodium = runJs ? sodiumModule : null;

  const results = [];

  // SecretBox (1 MiB)
  const secretboxData = new Uint8Array(MB).fill(0x2a);
  const secretboxKey = new Uint8Array(32).fill(0x11);
  const secretboxNonce = new Uint8Array(24).fill(0x22);
  const secretboxIters = 50 * iterScale;

  if (runRust) {
    results.push({
      impl: 'rust-wasm',
      case: 'secretbox',
      op: 'encrypt',
      sizeBytes: secretboxData.length,
      iterations: secretboxIters,
      durationMs: bench(secretboxIters, warmupIterations, () => {
        const ciphertext = wasmApi.secretbox_encrypt(secretboxData, secretboxNonce, secretboxKey);
        return ciphertext[0];
      }),
    });
  }

  if (runJs) {
    results.push({
      impl: 'js-wasm',
      case: 'secretbox',
      op: 'encrypt',
      sizeBytes: secretboxData.length,
      iterations: secretboxIters,
      durationMs: bench(secretboxIters, warmupIterations, () => {
        const ciphertext = sodium.crypto_secretbox_easy(
          secretboxData,
          secretboxNonce,
          secretboxKey
        );
        return ciphertext[0];
      }),
    });
  }

  const rustSecretboxCiphertext = runRust
    ? wasmApi.secretbox_encrypt(secretboxData, secretboxNonce, secretboxKey)
    : null;
  const jsSecretboxCiphertext = runJs
    ? sodium.crypto_secretbox_easy(secretboxData, secretboxNonce, secretboxKey)
    : null;

  if (runRust) {
    results.push({
      impl: 'rust-wasm',
      case: 'secretbox',
      op: 'decrypt',
      sizeBytes: secretboxData.length,
      iterations: secretboxIters,
      durationMs: bench(secretboxIters, warmupIterations, () => {
        const plaintext = wasmApi.secretbox_decrypt(
          rustSecretboxCiphertext,
          secretboxNonce,
          secretboxKey
        );
        return plaintext[0];
      }),
    });
  }

  if (runJs) {
    results.push({
      impl: 'js-wasm',
      case: 'secretbox',
      op: 'decrypt',
      sizeBytes: secretboxData.length,
      iterations: secretboxIters,
      durationMs: bench(secretboxIters, warmupIterations, () => {
        const plaintext = sodium.crypto_secretbox_open_easy(
          jsSecretboxCiphertext,
          secretboxNonce,
          secretboxKey
        );
        return plaintext[0];
      }),
    });
  }

  // Stream (1 MiB, 50 MiB)
  for (const size of [1 * MB, 50 * MB]) {
    const data = new Uint8Array(size).fill(0x5a);
    const key = new Uint8Array(32).fill(0x33);
    const baseIters = size >= 50 * MB ? 3 : 10;
    const iterations = baseIters * iterScale;
    const chunks = chunkCount(data.length);

    if (runRust) {
      results.push({
        impl: 'rust-wasm',
        case: 'stream',
        op: 'encrypt',
        sizeBytes: data.length,
        iterations,
        durationMs: bench(iterations, warmupIterations, () => {
          const encryptor = new wasmApi.StreamEncryptor(key);
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
    }

    if (runJs) {
      results.push({
        impl: 'js-wasm',
        case: 'stream',
        op: 'encrypt',
        sizeBytes: data.length,
        iterations,
        durationMs: bench(iterations, warmupIterations, () => {
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
    }

    let rustHeader = null;
    let rustCipherChunks = null;
    if (runRust) {
      const rustEnc = new wasmApi.StreamEncryptor(key);
      rustHeader = rustEnc.header;
      rustCipherChunks = [];
      let rustOffset = 0;
      for (let index = 0; index < chunks; index += 1) {
        const end = Math.min(rustOffset + STREAM_CHUNK, data.length);
        const chunk = data.subarray(rustOffset, end);
        const isFinal = index + 1 === chunks;
        rustCipherChunks.push(rustEnc.push(chunk, isFinal));
        rustOffset = end;
      }
    }

    let jsHeader = null;
    let jsCipherChunks = null;
    if (runJs) {
      const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(
        key
      );
      jsHeader = header;
      jsCipherChunks = [];
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
    }

    if (runRust) {
      results.push({
        impl: 'rust-wasm',
        case: 'stream',
        op: 'decrypt',
        sizeBytes: data.length,
        iterations,
        durationMs: bench(iterations, warmupIterations, () => {
          const decryptor = new wasmApi.StreamDecryptor(rustHeader, key);
          for (const chunk of rustCipherChunks) {
            const plaintext = decryptor.pull(chunk);
            if (plaintext[0] === 255) {
              return 1;
            }
          }
          return 0;
        }),
      });
    }

    if (runJs) {
      results.push({
        impl: 'js-wasm',
        case: 'stream',
        op: 'decrypt',
        sizeBytes: data.length,
        iterations,
        durationMs: bench(iterations, warmupIterations, () => {
          const decState = initPullState(sodium, jsHeader, key);
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
  }

  // Argon2id (interactive params)
  const argonIters = 3 * iterScale;
  const argonSalt = new Uint8Array(sodium.crypto_pwhash_SALTBYTES).fill(0x7b);

  if (runRust) {
    results.push({
      impl: 'rust-wasm',
      case: 'argon2id',
      op: 'derive',
      sizeBytes: 0,
      iterations: argonIters,
      durationMs: bench(argonIters, warmupIterations, () => {
        const key = wasmApi.argon2_derive('benchmark-password', argonSalt, ARGON_MEM, ARGON_OPS);
        return key[0];
      }),
    });
  }

  if (runJs) {
    results.push({
      impl: 'js-wasm',
      case: 'argon2id',
      op: 'derive',
      sizeBytes: 0,
      iterations: argonIters,
      durationMs: bench(argonIters, warmupIterations, () => {
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
  }

  // Auth flow (signup + login)
  const authIters = 3 * iterScale;
  const authPassword = 'benchmark-password';

  if (runRust) {
    results.push({
      impl: 'rust-wasm',
      case: 'auth',
      op: 'signup',
      sizeBytes: 0,
      iterations: authIters,
      durationMs: bench(authIters, warmupIterations, () => {
        const loginKey = wasmApi.auth_signup(authPassword);
        return loginKey[0];
      }),
    });
  }

  if (runJs) {
    results.push({
      impl: 'js-wasm',
      case: 'auth',
      op: 'signup',
      sizeBytes: 0,
      iterations: authIters,
      durationMs: bench(authIters, warmupIterations, () => {
        const { loginKey } = jsAuthSignup(sodium, authPassword);
        return loginKey[0];
      }),
    });
  }

  const rustAuthArtifacts = runRust ? wasmApi.auth_build_artifacts(authPassword) : null;
  const jsAuthArtifacts = runJs ? jsAuthBuildArtifacts(sodium, authPassword) : null;

  if (runRust) {
    results.push({
      impl: 'rust-wasm',
      case: 'auth',
      op: 'login',
      sizeBytes: 0,
      iterations: authIters,
      durationMs: bench(authIters, warmupIterations, () => {
        const masterKey = wasmApi.auth_login(
          authPassword,
          rustAuthArtifacts.key_attrs_json,
          rustAuthArtifacts.encrypted_token
        );
        return masterKey[0];
      }),
    });
  }

  if (runJs) {
    results.push({
      impl: 'js-wasm',
      case: 'auth',
      op: 'login',
      sizeBytes: 0,
      iterations: authIters,
      durationMs: bench(authIters, warmupIterations, () => {
        const token = jsAuthLogin(
          sodium,
          authPassword,
          jsAuthArtifacts.keyAttrs,
          jsAuthArtifacts.encryptedToken
        );
        return token[0];
      }),
    });
  }

  renderResults(results, {
    warmupIterations,
    iterScale,
    runRust,
    runJs,
  });
  setStatus('Done');
}

function setupUi() {
  const runButton = document.getElementById('run-bench');
  runButton.addEventListener('click', async () => {
    runButton.disabled = true;
    try {
      await runBench();
    } catch (err) {
      setStatus(`Error: ${err}`);
    } finally {
      runButton.disabled = false;
    }
  });
}

setupUi();
