import { ensureAuthToken } from "./local-user";
import { clientPackageName, type AppName } from "./types/app";

/**
 * The client package name to include as the "X-Client-Package" header in
 * authenticated requests.
 */
let _clientPackageName: string | undefined;

/**
 * Set the client package name (corresponding to the given {@link appName}) that
 * should be included as the "X-Client-Package" header in authenticated
 * requests.
 *
 * This state is persisted in memory, and can be cleared using
 * {@link clearHTTPState}.
 *
 * @param appName The {@link AppName} of the current app.
 */
export const setAppNameForAuthenticatedRequests = (appName: AppName) => {
    _clientPackageName = clientPackageName[appName];
};

/**
 * Forget the effects of a previous {@link setAppNameForAuthenticatedRequests}.
 */
export const clearHTTPState = () => {
    _clientPackageName = undefined;
};

/**
 * Return headers that should be passed alongwith (almost) all authenticated
 * `fetch` calls that we make to our API servers.
 *
 * This uses in-memory state initialized using
 * {@link setAppNameForAuthenticatedRequests}.
 */
export const authenticatedRequestHeaders = (): Record<string, string> => {
    const headers: Record<string, string> = {
        "X-Auth-Token": ensureAuthToken(),
    };
    if (_clientPackageName) headers["X-Client-Package"] = _clientPackageName;
    return headers;
};
