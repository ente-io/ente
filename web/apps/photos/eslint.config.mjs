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
            /** TODO: Disabled as we migrate, try to prune these again */
            "react-hooks/exhaustive-deps": "off",
        },
    },
];
