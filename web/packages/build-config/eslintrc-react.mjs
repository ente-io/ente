import reactPlugin from "eslint-plugin-react";
import hooksPlugin from "eslint-plugin-react-hooks";
import reactRefreshPlugin from "eslint-plugin-react-refresh";
import config from "./eslintrc-base.mjs";

export default [
    ...config,
    {
        files: ["**/*.{jsx,tsx}"],
        ...reactPlugin.configs.flat.recommended,
        ...reactPlugin.configs.flat["jsx-runtime"],
        settings: {
            react: {
                version: "detect",
            },
        },
        plugins: {
            "react-hooks": hooksPlugin,
            "react-refresh": reactRefreshPlugin,
        },
        rules: {
            ...hooksPlugin.configs.recommended.rules,
            // Apparently Fast refresh only works if a file only exports
            // components, and this rule warns about that.
            //
            // Constants are okay though (otherwise we'll need to create
            // unnecessary helper files).
            "react-refresh/only-export-components": [
                "warn",
                { allowConstantExport: true },
            ],
        },
    },
];

// module.exports = {
//     rules: {
//         /* The rule is misguided - only the opener should be omitted, not the
//            referrer. */
//         "react/jsx-no-target-blank": ["warn", { allowReferrer: true }],
//         /* Otherwise we need to do unnecessary boilerplating when using memo. */
//         "react/display-name": "off",
//         /* Next.js supports the JSX transform introduced in React 17 */
//         "react/react-in-jsx-scope": "off",
//         /* Without React in scope, this rule starts causing false positives (We
//            don't use prop types in our own code anyways). */
//         "react/prop-types": "off",
//     },
// };
