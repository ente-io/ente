import { appName } from "ente-base/app";

/**
 * The default page ("home route") for each of our apps.
 *
 * This is where we redirect to after successful authentication.
 */
export const appHomeRoute: string = {
    accounts: "/passkeys",
    auth: "/auth",
    cast: "/" /* The cast app doesn't use this, this is an arbitrary value. */,
    locker: "/" /* The locker app also doesn't use this. */,
    photos: "/gallery",
}[appName];

let _stashedRedirect: string | undefined;

/**
 * An in-memory redirect saved during the login flow (mostly).
 */
export const stashedRedirect = () => _stashedRedirect;

export const stashRedirect = (r: string) => (_stashedRedirect = r);

export const unstashRedirect = () => {
    const r = _stashedRedirect;
    _stashedRedirect = undefined;
    return r;
};

export const clearStashedRedirect = () => (_stashedRedirect = undefined);
