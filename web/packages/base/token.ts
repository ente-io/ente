import { getKVS } from "./kv";

/**
 * Return the user's auth token, if present.
 *
 * The user's auth token is stored in KV DB after they have successfully logged
 * in. This function returns that saved auth token.
 *
 * The underlying data is stored in IndexedDB, and can be accessed from web
 * workers.
 */
export const getAuthToken = () => getKVS("token");

/**
 * Return the user's auth token, or throw an error.
 *
 * The user's auth token can be retrieved using {@link getAuthToken}. This
 * function is a wrapper which throws an error if the token is not found (which
 * should only happen if the user is not logged in).
 */
export const ensureAuthToken = async () => {
    const token = await getAuthToken();
    if (!token) throw new Error("Not logged in");
    return token;
};
