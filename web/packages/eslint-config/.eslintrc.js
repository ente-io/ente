module.exports = {
    extends: ["@ente/eslint-config"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        tsconfigRootDir: __dirname,
        project: "./tsconfig.json",
    },
    ignorePatterns: [".eslintrc.js"],
};
