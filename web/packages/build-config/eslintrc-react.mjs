import reactPlugin from "eslint-plugin-react";
import hooksPlugin from "eslint-plugin-react-hooks";
import reactRefreshPlugin from "eslint-plugin-react-refresh";
import config from "./eslintrc-base.mjs";

export default [
    ...config,
    {
        files: ["**/*.{jsx,tsx}"],
        ...reactPlugin.configs.flat.recommended,
    },
    {
        files: ["**/*.{jsx,tsx}"],
        ...reactPlugin.configs.flat["jsx-runtime"],
    },
    {
        files: ["**/*.{jsx,tsx}"],
        settings: {
            react: {
                version: "detect",
            },
        },
        rules: {
            // The rule is misguided - only the opener should be omitted, not
            // the referrer.
            "react/jsx-no-target-blank": ["warn", { allowReferrer: true }],
            // Otherwise we need to do unnecessary boilerplating when using memo.
            "react/display-name": "off",
            // Without React in scope, this rule starts causing false positives
            // (We don't use prop types in our own code anyways).
            "react/prop-types": "off",
        },
    },
    {
        files: ["**/*.{jsx,tsx}"],
        plugins: {
            "react-hooks": hooksPlugin,
            "react-refresh": reactRefreshPlugin,
        },
        rules: {
            ...hooksPlugin.configs.recommended.rules,
            // Apparently Fast refresh only works if a file only exports
            // components, and this rule warns if we break that that.
            //
            // Constants are okay though practically (otherwise we'll need to
            // create unnecessary helper files).
            "react-refresh/only-export-components": [
                "warn",
                { allowConstantExport: true },
            ],
        },
    },
];
