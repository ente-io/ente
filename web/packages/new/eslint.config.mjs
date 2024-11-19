import config from "@/build-config/eslintrc-react.mjs";

export default [
    ...config,
    {
        // TODO: These can be removed when we start using ffmpeg upstream. For
        // reasons I haven't investigated much, when we run eslint on our CI, it
        // seems to behave differently than locally and give a lot of warnings
        // that possibly arise from it not being able to locate ffmpeg-wasm.
        ignores: ["**/ffmpeg/worker.ts"],
    },
    {
        rules: {
            /** TODO: New during eslint 8=>9 migration */
            "@typescript-eslint/no-unused-vars": "off",
            "@typescript-eslint/no-unused-expressions": "off",
        },
    },
];
