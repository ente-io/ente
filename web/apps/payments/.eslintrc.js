module.exports = {
    extends: ["@/build-config/eslintrc-next"],
    parserOptions: {
        tsconfigRootDir: __dirname,
    },
    // TODO (MR): Figure out a way to not have to ignored the next config .js
    // ignorePatterns: [".eslintrc.js", "next.config.js"],
};
