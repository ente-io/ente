/* eslint-env node */
module.exports = {
    root: true,
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/strict-type-checked",
        "plugin:@typescript-eslint/stylistic-type-checked",
        "plugin:react/recommended",
        "plugin:react-hooks/recommended",
        "plugin:react/jsx-runtime",
    ],
    plugins: ["@typescript-eslint", "react-refresh"],
    parserOptions: { project: true },
    parser: "@typescript-eslint/parser",
    ignorePatterns: [".eslintrc.cjs", "vite.config.ts", "dist"],
    settings: { react: { version: "18.2" } },
    rules: {
        /* Allow numbers to be used in template literals */
        "@typescript-eslint/restrict-template-expressions": [
            "error",
            {
                allowNumber: true,
            },
        ],
        /* Allow void expressions as the entire body of an arrow function */
        "@typescript-eslint/no-confusing-void-expression": [
            "error",
            {
                ignoreArrowShorthand: true,
            },
        ],
        "react-refresh/only-export-components": [
            "warn",
            { allowConstantExport: true },
        ],
    },
};
