module.exports = {
    // When root is set to true, ESLint will stop looking for configuration files in parent directories.
    // This is required here to ensure desktop picks the right eslint config, where this app is
    // packaged as a submodule.
    root: true,
    extends: ['@ente/eslint-config'],
    parser: '@typescript-eslint/parser',
    parserOptions: {
        tsconfigRootDir: __dirname,
        project: './tsconfig.json',
    },
    ignorePatterns: ['.eslintrc.js', 'out', 'thirdparty', 'public'],
};
