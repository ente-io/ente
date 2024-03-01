/* eslint-env node */
module.exports = {
    extends: [
        "eslint:recommended",
        "plugin:react-hooks/recommended",
        "plugin:@typescript-eslint/strict-type-checked",
        "plugin:@typescript-eslint/stylistic-type-checked",
    ],
    plugins: ["@typescript-eslint", "react-namespace-import"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: true,
    },
    root: true,
    ignorePatterns: [".eslintrc.js"],
    rules: {
        // The recommended way to import React is:
        //
        //     import * as React from "react";
        //
        // This rule enforces that.
        "react-namespace-import/no-namespace-import": "error",
    },
};
