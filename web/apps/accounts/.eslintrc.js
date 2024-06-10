/*
module.exports = {
    // When root is set to true, ESLint will stop looking for configuration files in parent directories.
    // This is required here to ensure desktop picks the right eslint config, where this app is
    // packaged as a submodule.
    root: true,
    extends: ["@ente/eslint-config"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        tsconfigRootDir: __dirname,
        project: "./tsconfig.json",
    },
    ignorePatterns: [".eslintrc.js", "out", "next.config.js", "next-env.d.ts"],
};
*/
module.exports = {
    extends: ["@/build-config/eslintrc-next"],
    ignorePatterns: ["next.config.base.js"],
    /* TODO: Temporary overrides */
    rules: {
        "react/react-in-jsx-scope": "off",
        "react/prop-types": "off",
        "react-hooks/exhaustive-deps": "off",
        "@typescript-eslint/no-unsafe-assignment": "off",
        "@typescript-eslint/no-misused-promises": "off",
        "@typescript-eslint/no-floating-promises": "off",
        "@typescript-eslint/no-unsafe-member-access": "off",
        "@typescript-eslint/no-unsafe-assignment": "off",
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-unsafe-argument": "off",
        "@typescript-eslint/restrict-template-expressions": "off",
        "react-refresh/only-export-components": "off",
    },
};
