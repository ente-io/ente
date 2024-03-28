// @ts-check

/**
 * Configuration for the Next.js build
 *
 * See also:
 * - packages/next/next.config.base.js
 * - https://nextjs.org/docs/pages/api-reference/next-config-js
 *
 * @type {import("next").NextConfig}
 */
const nextConfig = {
    /* generate a static export when we run `next build` */
    output: "export",
    reactStrictMode: true,
};

module.exports = nextConfig;
