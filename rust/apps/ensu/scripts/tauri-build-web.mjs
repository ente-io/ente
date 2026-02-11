import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const rootDir = path.resolve(__dirname, "..");
const webDir = path.resolve(rootDir, "..", "..", "..", "web");

const yarnBin = process.platform === "win32" ? "yarn.cmd" : "yarn";

const child = spawn(yarnBin, ["build:ensu"], {
    cwd: webDir,
    stdio: "inherit",
    env: {
        ...process.env,
        ENTE_TAURI: "1",
    },
});

child.on("exit", (code) => process.exit(code ?? 1));
