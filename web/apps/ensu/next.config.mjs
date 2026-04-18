/* eslint-env node */

import nextConfig from "ente-base/next.config.base.js";
import packageJson from "./package.json" with { type: "json" };

/** @type {{ process?: { env?: Record<string, string> } }} */
const globalWithProcess = globalThis;
const env = globalWithProcess.process?.env;
const { version } = packageJson;
const isTauriBuild = env?.ENTE_TAURI === "1";
const rawBasePath = env?.ENTE_BASE_PATH ?? "";
const normalizedBasePath = rawBasePath
    ? rawBasePath.startsWith("/")
        ? rawBasePath
        : `/${rawBasePath}`
    : undefined;

export default {
    ...nextConfig,
    eslint: { ignoreDuringBuilds: true },
    typescript: { ignoreBuildErrors: true },
    env: { ...(nextConfig.env ?? {}), NEXT_PUBLIC_ENSU_VERSION: version },
    ...(isTauriBuild ? { output: "export" } : {}),
    ...(normalizedBasePath
        ? {
              basePath: normalizedBasePath,
              assetPrefix: normalizedBasePath,
              trailingSlash: true,
          }
        : {}),
};
