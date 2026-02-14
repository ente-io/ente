import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const rootDir = path.resolve(__dirname, "..");
const tauriConfigPath = path.join(rootDir, "src-tauri", "tauri.conf.json");
const devConfigPath = path.join(rootDir, "src-tauri", "tauri.conf.dev.json");

const port = process.env.ENSU_TAURI_PORT || process.env.PORT || "3010";

const rawConfig = await fs.readFile(tauriConfigPath, "utf8");
const config = JSON.parse(rawConfig);

config.build = config.build || {};
config.build.beforeDevCommand =
    `cd ../../../web && yarn build:wasm && yarn workspace ensu next dev -p ${port}`;
config.build.devPath = `http://localhost:${port}`;

await fs.writeFile(devConfigPath, JSON.stringify(config, null, 2));

const tauriBin = process.platform === "win32" ? "tauri.cmd" : "tauri";
const tauriPath = path.join(rootDir, "node_modules", ".bin", tauriBin);

const child = spawn(tauriPath, ["dev", "--config", devConfigPath], {
    stdio: "inherit",
    env: process.env,
    cwd: rootDir,
});

child.on("exit", (code) => process.exit(code ?? 1));
