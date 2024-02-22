/**
 * A build is considered as a development build if either the NODE_ENV is
 * environment variable is set to 'development'.
 *
 * NODE_ENV is automatically set to 'development' when we run `yarn dev`. From
 * Next.js docs:
 *
 * > If the environment variable NODE_ENV is unassigned, Next.js automatically
 *   assigns development when running the `next dev` command, or production for
 *   all other commands.
 */
export const isDevBuild = process.env.NODE_ENV === "development";
