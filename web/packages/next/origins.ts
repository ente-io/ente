import { getKV, setKV } from "@/next/kv";

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
 * @returns path prefixed by {@link apiOrigin}.
 */
export const apiURL = async (path: string) => (await apiOrigin()) + path;

/**
 * Return the overridden API origin, if one is defined by either (in priority
 * order):
 *
 * -   Setting the custom server on the landing page (See: [Note: Configuring
 *     custom server]); or by
 *
 * -   Setting the `NEXT_PUBLIC_ENTE_ENDPOINT` environment variable.
 *
 * Otherwise return undefined.
 */
export const customAPIOrigin = async () => {
    let origin = await getKV("apiOrigin");
    if (!origin) {
        // TODO: Migration of apiOrigin from local storage to indexed DB
        // Remove me after a bit (27 June 2024).
        const legacyOrigin = localStorage.getItem("apiOrigin");
        if (legacyOrigin !== null) {
            origin = legacyOrigin;
            if (origin) await setKV("apiOrigin", origin);
            localStorage.removeItem("apiOrigin");
        }
    }

    return origin ?? process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? undefined;
};

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
 * Return the origin that serves the accounts app.
 *
 * Defaults to our production instance, "https://accounts.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_ACCOUNTS_URL` environment
 * variable.
 */
export const accountsAppOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_ACCOUNTS_URL ?? `https://accounts.ente.io`;

/**
 * Return the origin that serves public albums.
 *
 * Defaults to our production instance, "https://albums.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT` environment
 * variable.
 */
export const albumsAppOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT ?? "https://albums.ente.io";

/**
 * Return the origin that serves the family dashboard which can be used to
 * create or manage family plans..
 *
 * Defaults to our production instance, "https://family.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_FAMILY_URL` environment variable.
 */
export const familyAppOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_FAMILY_URL ?? "https://family.ente.io";

/**
 * Return the origin that serves the payments app.
 *
 * Defaults to our production instance, "https://payments.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_PAYMENTS_URL` environment variable.
 */
export const paymentsAppOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_PAYMENTS_URL ?? "https://payments.ente.io";
