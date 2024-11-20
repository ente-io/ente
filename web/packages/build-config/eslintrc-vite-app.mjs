// @ts-check

import config from "./eslintrc-react.mjs";

// A base config for Vite apps.
export default [...config, { ignores: ["dist", ".env*"] }];
