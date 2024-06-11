module.exports = {
    extends: ["@/build-config/eslintrc-next"],
    ignorePatterns: ["next.config.js", "next-env.d.ts"],
    /* TODO: Temporary overrides */
    rules: {
        "react/react-in-jsx-scope": "off",
        "react-hooks/exhaustive-deps": "off",
        "@typescript-eslint/no-explicit-any": "off",
        "react-refresh/only-export-components": "off",
    },
};
