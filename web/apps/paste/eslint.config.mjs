import baseConfig from "ente-build-config/eslintrc-next-app.mjs";

export default [
    ...baseConfig,
    {
        // Vendored upstream QR generator source; keep lint checks off this file.
        ignores: ["src/features/paste/utils/qrcodegen.ts"],
    },
];
