/* eslint-env node */
module.exports = {
    extends: [
        "./eslintrc-base.js",
        "plugin:react/recommended",
        "plugin:react-hooks/recommended",
    ],
    plugins: ["react-refresh"],
    settings: { react: { version: "18.2" } },
    rules: {
        "react/jsx-no-target-blank": ["warn", { allowReferrer: true }],
        "react-refresh/only-export-components": [
            "warn",
            { allowConstantExport: true },
        ],
    },
};
