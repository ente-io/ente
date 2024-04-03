/* eslint-env node */
module.exports = {
    root: true,
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/strict-type-checked",
        "plugin:@typescript-eslint/stylistic-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parserOptions: { project: true },
    parser: "@typescript-eslint/parser",
    ignorePatterns: [".eslintrc.js"],
};
