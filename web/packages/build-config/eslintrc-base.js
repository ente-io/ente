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
                    arguments: false,
                    attributes: false,
                },
            },
        ],
        /* Allow force unwrapping potentially optional values.

           It is best if these can be avoided by restructuring the code, but
           there do arise legitimate scenarios where we know from code logic
           that the value should be present. Of course, the surrounding code
           might change causing that expectation to be falsified, but in certain
           cases there isn't much we can do other than throwing an exception.

           Instead of rolling our own such exception (which we in fact used to
           do at one point), rely on the JS's native undefined property access
           exception since that conveys more information in the logs.
         */
        "@typescript-eslint/no-non-null-assertion": "off",
    },
};
