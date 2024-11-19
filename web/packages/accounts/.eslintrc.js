module.exports = {
    extends: ["@/build-config/eslintrc-react"],
    rules: {
        /* TODO:
         * "This rule requires the `strictNullChecks` compiler option to be
         * turned on to function correctly"
         */
        "@typescript-eslint/prefer-nullish-coalescing": "off",
        "@typescript-eslint/no-unnecessary-condition": "off",
        "@typescript-eslint/no-unsafe-assignment": "off",
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-unsafe-return": "off",
        "@typescript-eslint/no-unsafe-member-access": "off",
        "@typescript-eslint/no-unsafe-argument": "off",
        "@typescript-eslint/no-unsafe-call": "off",
        /** TODO: Disabled as we migrate, try to prune these again */
        "@typescript-eslint/no-floating-promises": "off",
        "@typescript-eslint/no-unsafe-enum-comparison": "off",
        "@typescript-eslint/no-unnecessary-type-assertion": "off",
        "@typescript-eslint/array-type": "off",
        "@typescript-eslint/no-empty-function": "off",
        "@typescript-eslint/no-unnecessary-template-expression": "off",
        "@typescript-eslint/consistent-indexed-object-style": "off",
        "@typescript-eslint/prefer-promise-reject-errors": "off",
        "@typescript-eslint/no-useless-constructor": "off",
        "@typescript-eslint/dot-notation": "off",
        "@typescript-eslint/require-await": "off",
        "@typescript-eslint/no-var-requires": "off",
        "@typescript-eslint/prefer-optional-chain": "off",
        "@typescript-eslint/ban-types": "off",
        "@typescript-eslint/no-misused-promises": "off",
        "react-hooks/exhaustive-deps": "off",
        "react-hooks/rules-of-hooks": "off",
        "react-refresh/only-export-components": "off",
    },
};
