/* eslint-env node */
module.exports = {
    extends: [
        "./eslintrc-base.js",
        "plugin:react/recommended",
        "plugin:react-hooks/recommended",
    ],
    plugins: ["react-refresh"],
    settings: { react: { version: "18.2" } },
    rules: {
        /* The rule is misguided - only the opener should be omitted, not the
           referrer. */
        "react/jsx-no-target-blank": ["warn", { allowReferrer: true }],
        /* Otherwise we need to do unnecessary boilerplating when using memo. */
        "react/display-name": "off",
        "react-refresh/only-export-components": [
            "warn",
            { allowConstantExport: true },
        ],
    },
};
