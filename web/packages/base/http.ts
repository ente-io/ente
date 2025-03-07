import { retryAsyncOperation } from "@/utils/promise";
import { z } from "zod";
import { clientPackageName } from "./app";
import { ensureAuthToken } from "./local-user";
import log from "./log";

/**
 * Return headers that should be passed alongwith (almost) all authenticated
 * `fetch` calls that we make to our API servers.
 *
 * - The auth token
 * - The client package name.
 */
export const authenticatedRequestHeaders = async () => ({
    "X-Auth-Token": await ensureAuthToken(),
    "X-Client-Package": clientPackageName,
});

/**
 * Return headers that should be passed alongwith (almost) all unauthenticated
 * `fetch` calls that we make to our API servers.
 *
 * - The client package name.
 */
export const publicRequestHeaders = () => ({
    "X-Client-Package": clientPackageName,
});

/**
 * A set of credentials needed to make public collections related API requests.
 */
export interface PublicAlbumsCredentials {
    /**
     * An access token that does the same job as the "X-Auth-Token" for usual
     * authenticated API requests, except it will be passed as the
     * ""X-Auth-Access-Token" header.
     */
    accessToken: string;
    /**
     * [Note: Password token for public albums requests].
     *
     * A password protected access token. This is only needed for albums that
     * are behind a password. In such cases, the client needs to fetch this
     * extra token from remote (in exchange for the public album's password),
     * and then pass it as the "X-Auth-Access-Token-JWT" header in authenticated
     * public collections related API requests.
     */
    accessTokenJWT?: string | undefined;
}

/**
 * Return headers that should be passed alongwith public collection related
 * authenticated `fetch` calls that we make to our API servers.
 *
 * - The auth token.
 * - The password protected auth token (if provided).
 * - The client package name.
 */
export const authenticatedPublicAlbumsRequestHeaders = ({
    accessToken,
    accessTokenJWT,
}: PublicAlbumsCredentials) => ({
    "X-Auth-Access-Token": accessToken,
    ...(accessTokenJWT && { "X-Auth-Access-Token-JWT": accessTokenJWT }),
    "X-Client-Package": clientPackageName,
});

/**
 * A custom Error that is thrown if a fetch fails with a non-2xx HTTP status.
 */
export class HTTPError extends Error {
    res: Response;
    details: Record<string, string>;

    constructor(res: Response) {
        // Trim off any query parameters from the URL before logging, it may
        // have tokens.
        //
        // Nb: res.url is URL obtained after any redirects, and thus is not
        // necessarily the same as the request's URL.
        const url = new URL(res.url);
        url.search = "";
        super(`HTTP ${res.status} ${res.statusText} (${url.pathname})`);

        const requestID = res.headers.get("x-request-id");
        const details = { url: url.href, ...(requestID ? { requestID } : {}) };

        // Cargo culted from
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error#custom_error_types
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (Error.captureStackTrace) Error.captureStackTrace(this, HTTPError);

        this.name = this.constructor.name;
        this.res = res;
        this.details = details;
    }
}

/**
 * A convenience method that throws an {@link HTTPError} if the given
 * {@link Response} does not have a HTTP 2xx status.
 */
export const ensureOk = (res: Response) => {
    if (!res.ok) {
        const e = new HTTPError(res);
        log.error(`${e.message} ${JSON.stringify(e.details)}`);
        throw e;
    }
};

/**
 * Return true if this is a HTTP error with the given {@link httpStatus}.
 */
export const isHTTPErrorWithStatus = (e: unknown, httpStatus: number) =>
    e instanceof HTTPError && e.res.status == httpStatus;

/**
 * Return true if this is a HTTP "client" error.
 *
 * This is a convenience matcher to check if {@link e} is an instance of
 * {@link HTTPError} with a 4xx status code. Such errors are client errors, and
 * (generally) retrying them will not help.
 */
export const isHTTP4xxError = (e: unknown) =>
    e instanceof HTTPError && e.res.status >= 400 && e.res.status <= 499;

/**
 * Return true if this is a HTTP 401 error.
 *
 * For authenticated requests, an HTTP "401 Unauthorized" indicates that the
 * credentials (auth token) is not valid.
 */
export const isHTTP401Error = (e: unknown) =>
    e instanceof HTTPError && e.res.status == 401;

/**
 * Return `true` if this is an error because of a HTTP failure response returned
 * by museum with the given "code" and HTTP status.
 *
 * For some known set of errors, museum returns a payload of the form
 *
 *     {"code":"USER_NOT_REGISTERED","message":"User is not registered"}
 *
 * where the code can be used to match a specific reason for the HTTP request
 * failing. This function can be used as a predicate to check both the HTTP
 * status code and the "code" within the payload.
 */
export const isMuseumHTTPError = async (
    e: unknown,
    httpStatus: number,
    code: string,
) => {
    if (e instanceof HTTPError && e.res.status == httpStatus) {
        try {
            const payload = z
                .object({ code: z.string() })
                .parse(await e.res.json());
            return payload.code == code;
        } catch (e) {
            log.warn("Ignoring error when parsing error payload", e);
            return false;
        }
    }
    return false;
};
/**
 * A helper function to adapt {@link retryAsyncOperation} for HTTP fetches.
 *
 * This will ensure that the HTTP operation returning a non-200 OK status (as
 * matched by {@link ensureOk}) is also counted as an error when considering if
 * a request should be retried.
 */
export const retryEnsuringHTTPOk = (request: () => Promise<Response>) =>
    retryAsyncOperation(async () => {
        const r = await request();
        ensureOk(r);
        return r;
    });
