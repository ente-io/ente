import config from "ente-build-config/eslintrc-next-app.mjs";

export default [
    ...config,
    { ignores: [".next-desktop"] },
    {
        rules: {
            /* TODO:
             * "This rule requires the `strictNullChecks` compiler option to be
             * turned on to function correctly"
             */
            "@typescript-eslint/no-unnecessary-boolean-literal-compare": "off",
            "@typescript-eslint/no-unnecessary-condition": "off",
            "@typescript-eslint/no-unsafe-assignment": "off",
            "@typescript-eslint/no-explicit-any": "off",
            "@typescript-eslint/no-unsafe-return": "off",
            "@typescript-eslint/no-unsafe-member-access": "off",
            "@typescript-eslint/no-unsafe-argument": "off",
            "@typescript-eslint/no-unsafe-call": "off",
            /** TODO: Disabled as we migrate, try to prune these again */
            "@typescript-eslint/no-floating-promises": "off",
            "@typescript-eslint/no-unnecessary-type-assertion": "off",
            "@typescript-eslint/prefer-promise-reject-errors": "off",
            "react-hooks/exhaustive-deps": "off",
            "react-refresh/only-export-components": "off",
        },
    },
];
