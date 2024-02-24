module.exports = {
    extends: ["@/build-config/eslintrc-typescript-react"],
    parserOptions: {
        tsconfigRootDir: __dirname,
    },
    // TODO (MR): Figure out a way to not have to ignored the next config .js
    ignorePatterns: [".eslintrc.js", "next.config.base.js"],
};
