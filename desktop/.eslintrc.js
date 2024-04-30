/* eslint-env node */
module.exports = {
    root: true,
    extends: [
        "eslint:recommended",
        "plugin:@typescript-eslint/eslint-recommended",
        "plugin:@typescript-eslint/strict-type-checked",
        "plugin:@typescript-eslint/stylistic-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: true,
    },
    ignorePatterns: [".eslintrc.js", "app", "out", "dist"],
    env: {
        es2022: true,
        node: true,
    },
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
    },
};
