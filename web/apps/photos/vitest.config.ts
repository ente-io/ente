import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
    resolve: {
        alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
    },
    test: { include: ["tests/**/*.test.{ts,tsx}"] },
    // Next preserves JSX for its own compiler; component tests need it compiled.
    oxc: { jsx: { runtime: "automatic" } },
});
