import fs from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const _sodium = require('libsodium-wrappers-sumo');

const KB = 1024;
const MB = 1024 * 1024;
const STREAM_CHUNK = 64 * 1024;

const ARGON_MEM = 67_108_864; // 64 MiB
const ARGON_OPS = 2;

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

async function run() {
  await _sodium.ready;
  const sodium = _sodium;

  console.log('╔══════════════════════════════════════════════════════════════╗');
  console.log('║     JS libsodium benchmark (libsodium-wrappers)              ║');
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  const results = [];

  // SecretBox (1 MiB)
  const secretboxData = new Uint8Array(MB).fill(0x2a);
  const secretboxKey = new Uint8Array(32).fill(0x11);
  const secretboxNonce = new Uint8Array(24).fill(0x22);
  const secretboxIters = 50;

  results.push({
    impl: 'js-libsodium',
    case: 'secretbox',
    op: 'encrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const ciphertext = sodium.crypto_secretbox_easy(secretboxData, secretboxNonce, secretboxKey);
      return ciphertext[0];
    }),
  });

  const secretboxCiphertext = sodium.crypto_secretbox_easy(
    secretboxData,
    secretboxNonce,
    secretboxKey
  );

  results.push({
    impl: 'js-libsodium',
    case: 'secretbox',
    op: 'decrypt',
    sizeBytes: secretboxData.length,
    iterations: secretboxIters,
    durationMs: bench(secretboxIters, () => {
      const plaintext = sodium.crypto_secretbox_open_easy(
        secretboxCiphertext,
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
      impl: 'js-libsodium',
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
          const tag = index + 1 === chunks
            ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
            : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
          const ciphertext = sodium.crypto_secretstream_xchacha20poly1305_push(state, chunk, null, tag);
          offset = end;
          if (ciphertext[0] === 255) {
            return 1;
          }
        }
        return 0;
      }),
    });

    const { state: encState, header } = sodium.crypto_secretstream_xchacha20poly1305_init_push(key);
    const cipherChunks = [];
    let offset = 0;
    for (let index = 0; index < chunks; index += 1) {
      const end = Math.min(offset + STREAM_CHUNK, data.length);
      const chunk = data.subarray(offset, end);
      const tag = index + 1 === chunks
        ? sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
        : sodium.crypto_secretstream_xchacha20poly1305_TAG_MESSAGE;
      cipherChunks.push(sodium.crypto_secretstream_xchacha20poly1305_push(encState, chunk, null, tag));
      offset = end;
    }

    results.push({
      impl: 'js-libsodium',
      case: 'stream',
      op: 'decrypt',
      sizeBytes: data.length,
      iterations,
      durationMs: bench(iterations, () => {
        const decState = initPullState(sodium, header, key);
        for (const chunk of cipherChunks) {
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
    impl: 'js-libsodium',
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
