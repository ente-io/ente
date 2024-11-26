import config from "@/build-config/eslintrc-next-app.mjs";

export default [
    ...config,
    {
        rules: {
            // We want to turn this off globally, but after having revisited all
            // existing uses.
            "@typescript-eslint/prefer-nullish-coalescing": "off",
        },
    },
];
