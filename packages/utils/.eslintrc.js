/* eslint-env node */
module.exports = {
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: true,
        tsconfigRootDir: __dirname,
    },
    ignorePatterns: [".eslintrc.js"],
    root: true,
};
