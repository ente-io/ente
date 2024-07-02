module.exports = {
    extends: ["@/build-config/eslintrc-react"],
    // TODO: These can be removed when we start using ffmpeg upstream. For an reason
    // I haven't investigated much, when we run eslint on our CI, it seems to behave
    // differently than locally and give a lot of warnings that possibly arise from
    // it not being able to locate ffmpeg-wasm.
    ignorePatterns: ["**/ffmpeg/worker.ts"],
};
