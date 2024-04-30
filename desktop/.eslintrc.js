/* eslint-env node */
module.exports = {
    root: true,
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/eslint-recommended",
        /* What we really want eventually */
        "plugin:@typescript-eslint/strict-type-checked",
        // "plugin:@typescript-eslint/stylistic-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: true,
    },
    ignorePatterns: [".eslintrc.js", "app", "out", "dist"],
    env: {
        es2022: true,
        node: true,
    },
    rules: {
        "@typescript-eslint/restrict-template-expressions": [
            "error",
            {
                allowNumber: true,
            },
        ],
        /* Temporary (RIP) */
        "@typescript-eslint/no-unsafe-return": "off",
        "@typescript-eslint/no-confusing-void-expression": "off",
        "@typescript-eslint/no-misused-promises": "off",
        // "@typescript-eslint/no-floating-promises": "off",
    },
};
