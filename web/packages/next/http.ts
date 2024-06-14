import { ensureAuthToken } from "./local-user";
import { clientPackageName, type AppName } from "./types/app";

/**
 * Value for the the "X-Client-Package" header in authenticated requests.
 */
let _clientPackage: string | undefined;

/**
 * Remember that we should include the client package corresponding to the given
 * {@link appName} as the "X-Client-Package" header in authenticated requests.
 *
 * This state is persisted in memory, and can be cleared using
 * {@link clearHTTPState}.
 *
 * @param appName The {@link AppName} of the current app.
 */
export const setAppNameForAuthenticatedRequests = (appName: AppName) => {
    _clientPackage = clientPackageName(appName);
};

/**
 * Variant of {@link setAppNameForAuthenticatedRequests} that sets directly sets
 * the client package to the provided string.
 */
export const setClientPackageForAuthenticatedRequests = (p: string) => {
    _clientPackage = p;
};

/**
 * Forget the effects of a previous {@link setAppNameForAuthenticatedRequests}
 * or {@link setClientPackageForAuthenticatedRequests}.
 */
export const clearHTTPState = () => {
    _clientPackage = undefined;
};

/**
 * Return headers that should be passed alongwith (almost) all authenticated
 * `fetch` calls that we make to our API servers.
 *
 * This uses in-memory state (See {@link clearHTTPState}).
 */
export const authenticatedRequestHeaders = (): Record<string, string> => {
    const headers: Record<string, string> = {
        "X-Auth-Token": ensureAuthToken(),
    };
    if (_clientPackage) headers["X-Client-Package"] = _clientPackage;
    return headers;
};

/**
 * Return a headers object with "X-Client-Package" header if we have the client
 * package value available to us from local storage.
 */
export const clientPackageHeaderIfPresent = (): Record<string, string> => {
    const headers: Record<string, string> = {};
    if (_clientPackage) headers["X-Client-Package"] = _clientPackage;
    return headers;
};
