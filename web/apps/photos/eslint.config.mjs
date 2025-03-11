import config from "@/build-config/eslintrc-next-app.mjs";

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
            "@typescript-eslint/no-empty-function": "off",
            "@typescript-eslint/prefer-promise-reject-errors": "off",
            "@typescript-eslint/no-useless-constructor": "off",
            "@typescript-eslint/require-await": "off",
            "@typescript-eslint/no-misused-promises": "off",
            "@typescript-eslint/restrict-template-expressions": "off",
            "@typescript-eslint/no-inferrable-types": "off",
            "@typescript-eslint/no-base-to-string": "off",
            "@typescript-eslint/restrict-plus-operands": "off",
            "@typescript-eslint/no-unused-expressions": "off",
            "react-hooks/exhaustive-deps": "off",
            "react-refresh/only-export-components": "off",
        },
    },
];
