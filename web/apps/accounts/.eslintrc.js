module.exports = {
    extends: ["@/build-config/eslintrc-next"],
    ignorePatterns: ["next.config.js", "next-env.d.ts"],
    /* TODO: Temporary overrides */
    rules: {
        "react-hooks/exhaustive-deps": "off",
        "react-refresh/only-export-components": "off",
    },
};
