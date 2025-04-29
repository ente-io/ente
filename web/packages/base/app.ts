export const appNames = ["accounts", "auth", "cast", "photos"] as const;

/**
 * Arbitrary names that we used as keys for indexing various constants
 * corresponding to our apps that rely on this package.
 */
export type AppName = (typeof appNames)[number];

/**
 * The unique key for the app.
 *
 * This is the name of the Ente app which we're currently running as. It is used
 * as a key for various properties that are different across apps.
 *
 * Parts of our code are shared across apps. Some parts of them also run in
 * non-main thread execution contexts like web workers. So there isn't always an
 * easy way to figure out what the current app is.
 *
 * To solve this, we inject the app name during the build process. This is
 * available to all our code (shared packages, web workers).
 *
 * This constant employs an `as` cast to avoid incurring a dynamic check, and as
 * such may be incorrect (e.g. when a new app gets added). So apps should
 * dynamically validate and log it once somewhere during init.
 */
export const appName: AppName = process.env.appName as AppName;

/**
 * True if we're running in our desktop app.
 *
 * This is similar to checking for `globalThis.electron`, however the advantage
 * of this check is that it will also work inside web workers (whose globalThis
 * won't have an electron object defined).
 *
 * This check can still have false positives during dev mode if someone connects
 * their browser to port where the desktop app's web app is being served from in
 * dev mode. If in the future some code needs to definitely rule out those false
 * positives, it'd need a runtime check of the form
 * `navigator.userAgent.includes("Electron")`.
 */
export const isDesktop = process.env.isDesktop == "1";

/**
 * Version of the desktop app.
 *
 * This is only defined when {@link isDesktop} is true.
 */
export const desktopAppVersion = process.env.desktopAppVersion;

/**
 * Static (English) title for the app.
 *
 * This is shown until we have the localized version.
 */
export const staticAppTitle = {
    accounts: "Ente Accounts",
    auth: "Ente Auth",
    cast: "Ente Photos",
    photos: "Ente Photos",
}[appName];

/**
 * Client "package names" for our app.
 *
 * The package name is used as the (a) "X-Client-Package" header in API
 * requests, and (b) as the identifier in inline user agent strings in payloads.
 *
 * In cases where this code works for both a web and a desktop app for the same
 * app (currently only photos), this will be the platform specific package name.
 */
export const clientPackageName = (() => {
    if (isDesktop) {
        if (appName != "photos")
            throw new Error(`Unsupported desktop appName ${appName}`);
        if (!desktopAppVersion)
            throw new Error(`desktopAppVersion is not defined`);
        return `io.ente.photos.desktop/${desktopAppVersion}`;
    }
    return {
        accounts: "io.ente.accounts.web",
        auth: "io.ente.auth.web",
        cast: "io.ente.cast.web",
        photos: "io.ente.photos.web",
    }[appName];
})();
