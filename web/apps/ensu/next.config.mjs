/* eslint-env node */

import nextConfig from "ente-base/next.config.base.js";

/** @type {{ process?: { env?: Record<string, string> } }} */
const globalWithProcess = globalThis;
const env = globalWithProcess.process?.env;
const isTauriBuild = env?.ENTE_TAURI === "1";

export default { ...nextConfig, ...(isTauriBuild ? { output: "export" } : {}) };
