import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const rustPath = args[0] || 'bench-rust.json';
const jsPath = args[1] || 'bench-js.json';

function loadResults(filePath) {
  const resolved = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(resolved)) {
    throw new Error(`Missing results file: ${resolved}`);
  }

  const raw = JSON.parse(fs.readFileSync(resolved, 'utf8'));
  const items = Array.isArray(raw) ? raw : raw.results;
  if (!Array.isArray(items)) {
    throw new Error(`Invalid results format in ${resolved}`);
  }

  return items.map((item) => ({
    impl: item.impl ?? item.implementation ?? 'unknown',
    case: item.case,
    op: item.op ?? item.operation,
    sizeBytes: item.sizeBytes ?? item.size_bytes ?? 0,
    iterations: item.iterations ?? 0,
    durationMs: item.durationMs ?? item.duration_ms ?? 0,
  }));
}

function formatSize(bytes) {
  if (!bytes) {
    return 'n/a';
  }
  return `${(bytes / (1024 * 1024)).toFixed(1)}MiB`;
}

function printHeader() {
  console.log('Impl        | Case        | Op      | Size     | Iters | ms/op     | Rate');
  console.log('------------+-------------+---------+----------+-------+-----------+------------');
}

function rowRate(row) {
  const seconds = row.durationMs / 1000.0;
  if (!row.sizeBytes) {
    return { label: 'ops/s', value: row.iterations / seconds };
  }
  const mib = row.sizeBytes / (1024 * 1024);
  return { label: 'MiB/s', value: (mib * row.iterations) / seconds };
}

function printRow(row) {
  const size = formatSize(row.sizeBytes);
  const msPerOp = row.durationMs / row.iterations;
  const { label, value } = rowRate(row);

  console.log(
    `${row.impl.padEnd(11)} | ${row.case.padEnd(11)} | ${row.op.padEnd(7)} | ${size
      .toString()
      .padStart(8)} | ${row.iterations
      .toString()
      .padStart(5)} | ${msPerOp.toFixed(3).padStart(9)} ms/op | ${label} ${value
      .toFixed(2)
      .padStart(8)}`
  );
}

function printSummary(rows) {
  const groups = new Map();

  for (const row of rows) {
    const key = `${row.case}|${row.op}|${row.sizeBytes}`;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(row);
  }

  console.log('\nRust-core baseline summary (percent vs rust-core)');

  const keys = [...groups.keys()].sort();
  for (const key of keys) {
    const [caseName, op, sizeText] = key.split('|');
    const sizeBytes = Number(sizeText);
    const group = groups.get(key).slice();
    const sizeLabel = formatSize(sizeBytes);

    const core = group.find((row) => row.impl === 'rust-core');
    if (!core) {
      console.log(`- ${caseName} ${op} ${sizeLabel}: missing rust-core baseline`);
      continue;
    }

    const coreMs = core.durationMs / core.iterations;
    const others = group.filter((row) => row.impl !== 'rust-core');

    if (others.length === 0) {
      console.log(`- ${caseName} ${op} ${sizeLabel}: rust-core only`);
      continue;
    }

    const fastest = group.reduce((best, row) => {
      const rowMs = row.durationMs / row.iterations;
      const bestMs = best.durationMs / best.iterations;
      return rowMs < bestMs ? row : best;
    }, group[0]);

    if (fastest.impl === 'rust-core') {
      let closest = others[0];
      let closestPercent = Math.abs(
        (closest.durationMs / closest.iterations - coreMs) / coreMs
      ) * 100;

      for (const row of others.slice(1)) {
        const rowMs = row.durationMs / row.iterations;
        const percent = Math.abs((rowMs - coreMs) / coreMs) * 100;
        if (percent < closestPercent) {
          closest = row;
          closestPercent = percent;
        }
      }

      console.log(
        `- ${caseName} ${op} ${sizeLabel}: rust-core by ${closestPercent.toFixed(1)}% vs ${closest.impl}`
      );
      continue;
    }

    const fastestMs = fastest.durationMs / fastest.iterations;
    const percent = Math.abs((coreMs - fastestMs) / coreMs) * 100;

    console.log(
      `- ${caseName} ${op} ${sizeLabel}: ${fastest.impl} by ${percent.toFixed(1)}% vs rust-core`
    );
  }
}

function main() {
  const rustRows = loadResults(rustPath);
  const jsRows = loadResults(jsPath);

  const rows = [...rustRows, ...jsRows].sort((a, b) => {
    if (a.case !== b.case) return a.case.localeCompare(b.case);
    if (a.op !== b.op) return a.op.localeCompare(b.op);
    if (a.sizeBytes !== b.sizeBytes) return a.sizeBytes - b.sizeBytes;
    return a.impl.localeCompare(b.impl);
  });

  printHeader();
  for (const row of rows) {
    printRow(row);
  }
  printSummary(rows);
}

try {
  main();
} catch (err) {
  console.error(err.message ?? err);
  process.exit(1);
}
