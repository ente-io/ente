import config from "@/build-config/eslintrc-next-app.mjs";

export default [
    ...config,
    {
        rules: {
            /* TODO:
             * "This rule requires the `strictNullChecks` compiler option to be
             * turned on to function correctly"
             */
            "@typescript-eslint/prefer-nullish-coalescing": "off",
            "@typescript-eslint/no-unnecessary-condition": "off",
            /** TODO: Disabled as we migrate, try to prune these again */
            "react-hooks/exhaustive-deps": "off",
        },
    },
];
