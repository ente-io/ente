import { ensureAuthToken } from "./local-user";
import { clientPackageName } from "./types/app";

/**
 * Return headers that should be passed alongwith (almost) all authenticated
 * `fetch` calls that we make to our API servers.
 *
 * -   The auth token
 * -   The client package name.
 */
export const authenticatedRequestHeaders = (): Record<string, string> => ({
    "X-Auth-Token": ensureAuthToken(),
    "X-Client-Package": clientPackageName,
});

/**
 * Return a headers object with "X-Client-Package" header set to the client
 * package name of the current app.
 */
export const clientPackageHeader = (): Record<string, string> => ({
    "X-Client-Package": clientPackageName,
});
