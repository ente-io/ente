import config from "@/build-config/eslintrc-react.mjs";

export default [...config, { ignores: ["next.config.base.js"] }];
