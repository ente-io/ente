/* eslint-env node */
module.exports = {
    root: true,
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/strict-type-checked",
        "plugin:@typescript-eslint/stylistic-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parserOptions: { project: true },
    parser: "@typescript-eslint/parser",
    ignorePatterns: [".eslintrc.js"],
    rules: {
        /* Allow numbers to be used in template literals */
        "@typescript-eslint/restrict-template-expressions": [
            "error",
            {
                allowNumber: true,
            },
        ],
        /* Allow void expressions as the entire body of an arrow function */
        "@typescript-eslint/no-confusing-void-expression": [
            "error",
            {
                ignoreArrowShorthand: true,
            },
        ],
        /*
          Allow async functions to be passed as JSX attributes expected to be
          functions that return void (typically onFoo event handlers).

          This should be safe since we have registered global unhandled Promise
          handlers.
         */
        "@typescript-eslint/no-misused-promises": [
            "error",
            {
                checksVoidReturn: {
                    attributes: false,
                },
            },
        ],
    },
};
