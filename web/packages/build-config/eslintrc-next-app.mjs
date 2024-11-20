// @ts-check

import config from "./eslintrc-react.mjs";

// A base config for Next.js apps.
export default [
    ...config,
    {
        ignores: [
            "out",
            ".next",
            "public",
            ".env*",
            "next.config.js",
            "next-env.d.ts",
        ],
    },
];
