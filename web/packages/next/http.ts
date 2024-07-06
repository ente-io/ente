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

/**
 * A custom Error that is thrown if a fetch fails with a non-2xx HTTP status.
 */
export class HTTPError extends Error {
    res: Response;

    constructor(res: Response) {
        // Nb: res.url is URL obtained after any redirects, and thus is not
        // necessarily the same as the request's URL.
        super(`Fetch failed: ${res.url}: HTTP ${res.status} ${res.statusText}`);

        // Cargo culted from
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error#custom_error_types
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (Error.captureStackTrace) Error.captureStackTrace(this, HTTPError);

        this.name = this.constructor.name;
        this.res = res;
    }
}

/**
 * A convenience method that throws an {@link HTTPError} if the given
 * {@link Response} does not have a HTTP 2xx status.
 */
export const ensure2xx = (res: Response) => {
    if (!res.ok) throw new HTTPError(res);
};

/**
 * Return true if this is a HTTP "client" error.
 *
 * This is a convenience matcher to check if {@link e} is an instance of
 * {@link HTTPError} with a 4xx status code. Such errors are client errors, and
 * (generally) retrying them will not help.
 */
export const isHTTP4xxError = (e: unknown) =>
    e instanceof HTTPError && e.res.status >= 400 && e.res.status <= 499;
