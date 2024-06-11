module.exports = {
    extends: ["@/build-config/eslintrc-next"],
    ignorePatterns: ["next.config.js", "next-env.d.ts"],
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
