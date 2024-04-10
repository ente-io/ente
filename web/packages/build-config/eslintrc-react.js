/* eslint-env node */
module.exports = {
    extends: [
        "./eslintrc-base.js",
        "plugin:react/recommended",
        "plugin:react-hooks/recommended",
    ],
    settings: { react: { version: "18.2" } },
};
