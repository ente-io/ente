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

/**
 * `true` if we're running in the default global context (aka the main thread)
 * of a web browser.
 *
 * In particular, this is `false` when we're running in a web worker,
 * irrespecitve of whether the worker is running in a Node.js context or a web
 * browser context.
 *
 * > We can be running in a browser context either if the user has the page open
 *   in a web browser, or if we're the renderer process of an Electron app.
 *
 * Note that this cannot be a constant, otherwise it'll get inlined during SSR
 * with the wrong value.
 */
export const haveWindow = () => typeof window !== "undefined";

/**
 * Return true if we are running in a [Web
 * Worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API)
 *
 * Note that this cannot be a constant, otherwise it'll get inlined during SSR
 * with the wrong value.
 */
export const inWorker = () => typeof importScripts === "function";
