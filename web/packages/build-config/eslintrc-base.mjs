// @ts-check

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
    eslint.configs.recommended,
    tseslint.configs.strictTypeChecked,
    tseslint.configs.stylisticTypeChecked,
    {
        languageOptions: {
            parserOptions: {
                projectService: true,
                tsconfigRootDir: import.meta.dirname,
            },
        },
        linterOptions: { reportUnusedDisableDirectives: "error" },
    },
    { ignores: ["eslint.config.mjs"] },
    {
        rules: {
            // Allow numbers to be used in template literals.
            "@typescript-eslint/restrict-template-expressions": [
                "error",
                { allowNumber: true },
            ],
            // Allow void expressions as the entire body of an arrow function.
            "@typescript-eslint/no-confusing-void-expression": [
                "error",
                { ignoreArrowShorthand: true },
            ],
            // Allow async functions to be passed as JSX attributes expected to
            // be functions that return void (typically onFoo event handlers).
            //
            // This should be safe since we have registered global unhandled
            // Promise handlers.
            "@typescript-eslint/no-misused-promises": [
                "error",
                { checksVoidReturn: { arguments: false, attributes: false } },
            ],
            // Allow force unwrapping potentially optional values.
            //
            // It is best if these can be avoided by restructuring the code, but
            // there do arise legitimate scenarios where we know from code logic
            // that the value should be present. Of course, the surrounding code
            // might change causing that expectation to be falsified, but in
            // certain cases there isn't much we can do other than throwing an
            // exception.
            //
            // Instead of rolling our own such exception (which we in fact used
            // to do at one point), rely on the JS's native undefined property
            // access exception since that conveys more information in the logs.
            "@typescript-eslint/no-non-null-assertion": "off",
            // Allow `while(true)` etc.
            "@typescript-eslint/no-unnecessary-condition": [
                "error",
                { allowConstantLoopConditions: true },
            ],
        },
    },
);
