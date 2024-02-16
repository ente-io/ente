// @ts-check

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

console.log(tseslint);

export default tseslint.config(
    eslint.configs.recommended,
    ...tseslint.configs.recommended
);
