import { clientPackageName } from "./app";
import { ensureAuthToken } from "./local-user";

/**
 * Return headers that should be passed alongwith (almost) all authenticated
 * `fetch` calls that we make to our API servers.
 *
 * -   The auth token
 * -   The client package name.
 */
export const authenticatedRequestHeaders = async () => ({
    "X-Auth-Token": await ensureAuthToken(),
    "X-Client-Package": clientPackageName,
});

/**
 * Return a headers object with "X-Client-Package" header set to the client
 * package name of the current app.
 */
export const clientPackageHeader = () => ({
    "X-Client-Package": clientPackageName,
});
