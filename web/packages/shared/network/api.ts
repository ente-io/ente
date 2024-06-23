import { nullToUndefined } from "@/utils/transform";

/**
 * Return the origin (scheme, host, port triple) that should be used for making
 * API requests to museum.
 *
 * This defaults to {@link defaultAPIOrigin}, but can be overridden when self
 * hosting or developing by setting the `NEXT_PUBLIC_ENTE_ENDPOINT` environment
 * variable.
 */
export const apiOrigin = () => customAPIOrigin() ?? defaultAPIOrigin;

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
export const customAPIOrigin = () =>
    nullToUndefined(localStorage.getItem("apiOrigin")) ??
    process.env.NEXT_PUBLIC_ENTE_ENDPOINT ??
    undefined;

/**
 * Default value of {@link apiOrigin}: "https://api.ente.io", Ente's production
 * API servers.
 */
export const defaultAPIOrigin = "https://api.ente.io";

/** Deprecated, use {@link apiOrigin} instead. */
export const getEndpoint = apiOrigin;

/**
 * Return the origin that should be used for uploading files.
 *
 * This defaults to `https://uploader.ente.io`, serviced by a Cloudflare worker
 * (see infra/workers/uploader). But if a {@link customAPIOrigin} is set then
 * this value is set to the {@link customAPIOrigin} itself, effectively
 * bypassing the Cloudflare worker for non-Ente deployments.
 */
export const uploaderOrigin = () =>
    customAPIOrigin() ?? "https://uploader.ente.io";

/**
 * Return the URL of the Ente Accounts app.
 *
 * Defaults to our production instance, "https://accounts.ente.io", but can be
 * overridden by setting the `NEXT_PUBLIC_ENTE_ACCOUNTS_URL` environment
 * variable.
 */
export const accountsAppURL = () =>
    process.env.NEXT_PUBLIC_ENTE_ACCOUNTS_URL ?? `https://accounts.ente.io`;

export const getAlbumsURL = () => {
    const albumsURL = process.env.NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT;
    if (albumsURL) {
        return albumsURL;
    }
    return `https://albums.ente.io`;
};

/**
 * Return the URL for the family dashboard which can be used to create or manage
 * family plans.
 */
export const getFamilyPortalURL = () => {
    const familyURL = process.env.NEXT_PUBLIC_ENTE_FAMILY_URL;
    if (familyURL) {
        return familyURL;
    }
    return `https://family.ente.io`;
};

/**
 * Return the URL for the host that handles payment related functionality.
 */
export const getPaymentsURL = () => {
    const paymentsURL = process.env.NEXT_PUBLIC_ENTE_PAYMENTS_URL;
    if (paymentsURL) {
        return paymentsURL;
    }
    return `https://payments.ente.io`;
};
