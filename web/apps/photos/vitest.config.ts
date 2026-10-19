import { defineConfig } from "vitest/config";

export default defineConfig({
    // Next preserves JSX for its own compiler; component tests need it compiled.
    oxc: { jsx: { runtime: "automatic" } },
});
