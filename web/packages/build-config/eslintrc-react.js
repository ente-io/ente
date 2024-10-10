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
        /* Apparently Fast refresh only works if a file only exports components,
           and this rule warns about that. Constants are okay though (otherwise
           we'll need to create unnecessary helper files). */
        "react-refresh/only-export-components": [
            "warn",
            { allowConstantExport: true },
        ],
        /* Next.js supports the JSX transform introduced in React 17 */
        "react/react-in-jsx-scope": "off",
    },
};
