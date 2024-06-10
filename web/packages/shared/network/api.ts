/**
 * Return the origin (scheme, host, port triple) that should be used for making
 * API requests to museum.
 *
 * This defaults to "https://api.ente.io", Ente's own servers, but can be
 * overridden when self hosting or developing by setting the
 * `NEXT_PUBLIC_ENTE_ENDPOINT` environment variable.
 */
export const apiOrigin = () => customAPIOrigin() ?? "https://api.ente.io";

/**
 * Return the overridden API origin, if one is defined by setting the
 * `NEXT_PUBLIC_ENTE_ENDPOINT` environment variable.
 *
 * Otherwise return undefined.
 */
export const customAPIOrigin = () =>
    process.env.NEXT_PUBLIC_ENTE_ENDPOINT ?? undefined;

/** Deprecated, use {@link apiOrigin} instead. */
export const getEndpoint = apiOrigin;

export const getUploadEndpoint = () => {
    const endpoint = process.env.NEXT_PUBLIC_ENTE_ENDPOINT;
    if (endpoint) {
        return endpoint;
    }
    return `https://uploader.ente.io`;
};

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
