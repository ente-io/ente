import { nullToUndefined } from "@/utils/transform";

/**
 * Return the origin (scheme, host, port triple) that should be used for making
 * API requests to museum.
 *
 * This defaults "https://api.ente.io", Ente's production API servers. but can
 * be overridden when self hosting or developing (see {@link customAPIOrigin}).
 */
export const apiOrigin = () => customAPIOrigin() ?? "https://api.ente.io";

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
