import { getKVS, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";
import { RemoteKeyAttributes, type KeyAttributes } from "./user";

export type LocalStorageKey =
    | "user"
    // See also savedKeyAttributes.
    | "keyAttributes"
    | "originalKeyAttributes"
    | "isFirstLogin"
    | "justSignedUp"
    | "showBackButton"
    // Moved to ente-accounts
    // "srpSetupAttributes"
    | "srpAttributes"
    | "referralSource";

export const setData = (key: LocalStorageKey, value: object) =>
    localStorage.setItem(key, JSON.stringify(value));

export const removeData = (key: LocalStorageKey) =>
    localStorage.removeItem(key);

/**
 * [Note: Accounts DB]
 *
 * The accounts package stores various state both during the login / signup
 * flow, and post login to identify the logged in user.
 *
 * This state is stored in local storage.
 *
 * Most of this state is meant to be transitory - various bits and bobs that we
 * accumulate and want to persist as the user goes through the login or signup
 * flow. One the user is successfully logged in and the first pull has
 * completed, then only a few of these are expected to remain:
 *
 * - "user"
 * - "keyAttributes"
 * - "srpAttributes"
 */
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

/**
 * Return the user's {@link KeyAttributes} if they are present in local storage.
 *
 * The key attributes are stored in the browser's localStorage. Thus, this
 * function only works from the main thread, not from web workers (local storage
 * is not accessible to web workers).
 */
export const savedKeyAttributes = (): KeyAttributes | undefined => {
    const jsonString = localStorage.getItem("keyAttributes");
    if (!jsonString) return undefined;
    return RemoteKeyAttributes.parse(JSON.parse(jsonString));
};

/**
 * Save the user's {@link KeyAttributes} in local storage.
 *
 * Use {@link savedKeyAttributes} to retrieve them.
 */
export const saveKeyAttributes = (keyAttributes: KeyAttributes) =>
    localStorage.setItem("keyAttributes", JSON.stringify(keyAttributes));

export const getToken = (): string => {
    const token = getData("user")?.token;
    return token;
};

export const isFirstLogin = () => getData("isFirstLogin")?.status ?? false;

export function setIsFirstLogin(status: boolean) {
    setData("isFirstLogin", { status });
}

export const justSignedUp = () => getData("justSignedUp")?.status ?? false;

export function setJustSignedUp(status: boolean) {
    setData("justSignedUp", { status });
}

export function getLocalReferralSource() {
    return getData("referralSource")?.source;
}

export function setLocalReferralSource(source: string) {
    setData("referralSource", { source });
}
