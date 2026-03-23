import { getKVS, removeKV, setKV } from "./kv";

/**
 * Return the user's auth token, or throw an error.
 *
 * The user's auth token can be retrieved using {@link savedAuthToken}. This
 * function is a wrapper which throws an error if the token is not found (which
 * should only happen if the user is not logged in).
 */
export const ensureAuthToken = async () => {
    const token = await savedAuthToken();
    if (!token) throw new Error("Not logged in");
    return token;
};

/**
 * Return the user's auth token, if available.
 *
 * The user's auth token is stored in KV DB using {@link saveAuthToken} during
 * the login / signup flow. This function returns that saved auth token.
 *
 * The underlying data is stored in IndexedDB, and can be accessed from web
 * workers.
 *
 * If your code is running in a context where the user is already expected to be
 * logged in, use {@link ensureAuthToken} instead.
 */
export const savedAuthToken = () => getKVS("token");

/**
 * Save the user's auth token in KV DB.
 *
 * This is the setter corresponding to {@link savedAuthToken}.
 */
export const saveAuthToken = (token: string) => setKV("token", token);

/**
 * Remove the user's auth token from KV DB.
 *
 * See {@link saveAuthToken}.
 */
export const removeAuthToken = () => removeKV("token");
