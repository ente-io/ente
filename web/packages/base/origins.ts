import { getKVS } from "@/base/kv";

/**
 * Return the origin (scheme, host, port triple) that should be used for making
 * API requests to museum.
 *
 * This defaults "https://api.ente.io", Ente's production API servers. but can
 * be overridden when self hosting or developing (see {@link customAPIOrigin}).
 */
export const apiOrigin = async () =>
    (await customAPIOrigin()) ?? "https://api.ente.io";

/**
 * A convenience function to construct an endpoint in a one-liner.
 *
 * This avoids us having to create a temporary variable or otherwise complicate
 * the call sites since async functions cannot be used inside template literals.
 *
 * @param path The URL path usually, but can be anything that needs to be
 * suffixed to the origin. It must begin with a "/".
 *
 * @param queryParams An optional object containing query params. This is
 * appended to the generated URL after funneling it through
 * {@link URLSearchParams}.
 *
 * @returns path prefixed by {@link apiOrigin}.
 */
export const apiURL = async (
    path: string,
    queryParams?: Record<string, string>,
) => {
    let url = (await apiOrigin()) + path;
    if (queryParams) {
        const params = new URLSearchParams(queryParams);
        url = `${url}?${params.toString()}`;
    }
    return url;
};

/**
 * Return the overridden API origin, if one is defined by either (in priority
 * order):
 *
 * - Setting the custom server on the landing page (See: [Note: Configuring
 *   custom server]); or by
 *
 * - Setting the `NEXT_PUBLIC_ENTE_ENDPOINT` environment variable.
 *
 * Otherwise return undefined.
 */
export const customAPIOrigin = async () =>
    (await getKVS("apiOrigin")) ??
    process.env.NEXT_PUBLIC_ENTE_ENDPOINT ??
    undefined;

/**
 * A convenience wrapper over {@link customAPIOrigin} that returns the only the
 * host part of the custom origin (if any).
 *
 * This is useful in places where we indicate the custom origin in the UI.
 */
export const customAPIHost = async () => {
    const origin = await customAPIOrigin();
    return origin ? new URL(origin).host : undefined;
};

/**
 * Return the origin that should be used for uploading files.
 *
 * This defaults to `https://uploader.ente.io`, serviced by a Cloudflare worker
 * (see infra/workers/uploader). But if a {@link customAPIOrigin} is set then
 * this value is set to the {@link customAPIOrigin} itself, effectively
 * bypassing the Cloudflare worker for non-Ente deployments.
 */
export const uploaderOrigin = async () =>
    (await customAPIOrigin()) ?? "https://uploader.ente.io";

/**
 * Return the origin that serves public albums.
 *
 * Defaults to our production instance, "https://albums.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT` environment
 * variable.
 */
export const albumsAppOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT ?? "https://albums.ente.io";
