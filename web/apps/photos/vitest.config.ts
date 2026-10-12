import { defineConfig } from "vitest/config";

export default defineConfig({
    oxc: { jsx: { runtime: "automatic" } },
    // Knip needs this to discover the default test entry points.
    test: {},
});
