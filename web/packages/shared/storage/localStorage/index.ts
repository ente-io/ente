import { getKVS, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";

export type LocalStorageKey =
    | "user"
    // See also savedKeyAttributes.
    | "keyAttributes"
    | "originalKeyAttributes"
    | "isFirstLogin"
    | "justSignedUp"
    | "showBackButton"
    | "export"
    // LOGS = "logs",
    // Migrated to (and only used by) useCollectionsSortByLocalState.
    | "collectionSortBy"
    // Moved to the new wrapper ente-base/local-storage
    // LOCALE = 'locale',
    // Moved to ente-accounts
    // "srpSetupAttributes"
    | "srpAttributes"
    | "referralSource";

export const setData = (key: LocalStorageKey, value: object) =>
    localStorage.setItem(key, JSON.stringify(value));

export const removeData = (key: LocalStorageKey) =>
    localStorage.removeItem(key);

export const getData = (key: LocalStorageKey) => {
    try {
        if (
            typeof localStorage == "undefined" ||
            typeof key == "undefined" ||
            typeof localStorage.getItem(key) == "undefined" ||
            localStorage.getItem(key) == "undefined"
        ) {
            return null;
        }
        const data = localStorage.getItem(key);
        return data && JSON.parse(data);
    } catch (e) {
        log.error(`Failed to Parse JSON for key ${key}`, e);
    }
};

// TODO: Migrate this to `local-user.ts`, with (a) more precise optionality
// indication of the constituent fields, (b) moving any fields that need to be
// accessed from web workers to KV DB.
//
// Creating a new function here to act as a funnel point.
export const setLSUser = async (user: object) => {
    await migrateKVToken(user);
    setData("user", user);
};

/**
 * Update the "token" KV with the token (if any) for the given {@link user}.
 *
 * This is an internal implementation details of {@link setLSUser} and doesn't
 * need to exposed conceptually. For now though, we need to call this externally
 * at an early point in the app startup to also copy over the token into KV DB
 * for existing users.
 *
 * This was added 1 July 2024, can be removed after a while and this code
 * inlined into `setLSUser` (tag: Migration).
 */
export const migrateKVToken = async (user: unknown) => {
    // Throw an error if the data is in local storage but not in IndexedDB. This
    // is a pre-cursor to inlining this code.
    // TODO: Remove this sanity check eventually when this code is revisited.
    const oldLSUser = getData("user");
    const wasMissing =
        oldLSUser &&
        typeof oldLSUser == "object" &&
        "token" in oldLSUser &&
        typeof oldLSUser.token == "string" &&
        !(await getKVS("token"));

    // eslint-disable-next-line @typescript-eslint/no-unused-expressions
    user &&
    typeof user == "object" &&
    "id" in user &&
    typeof user.id == "number"
        ? await setKV("userID", user.id)
        : await removeKV("userID");

    // eslint-disable-next-line @typescript-eslint/no-unused-expressions
    user &&
    typeof user == "object" &&
    "token" in user &&
    typeof user.token == "string"
        ? await setKV("token", user.token)
        : await removeKV("token");

    if (wasMissing)
        throw new Error(
            "The user's token was present in local storage but not in IndexedDB",
        );
};

/**
 * Return true if the user's data is in local storage but not in IndexedDB.
 *
 * This acts a sanity check on IndexedDB by ensuring that if the user has a
 * token in local storage, then it should also be present in IndexedDB.
 */
export const isLocalStorageAndIndexedDBMismatch = async () => {
    const oldLSUser = getData("user");
    return (
        oldLSUser &&
        typeof oldLSUser == "object" &&
        "token" in oldLSUser &&
        typeof oldLSUser.token == "string" &&
        !(await getKVS("token"))
    );
};
