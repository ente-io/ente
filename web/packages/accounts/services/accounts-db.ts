import { getKVS, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import { RemoteKeyAttributes, type KeyAttributes } from "./user";

export type LocalStorageKey =
    | "user"
    // See also savedKeyAttributes.
    | "keyAttributes"
    | "originalKeyAttributes"
    | "showBackButton"
    // Moved to ente-accounts
    // "srpSetupAttributes"
    | "srpAttributes";

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

export const setData = (key: LocalStorageKey, value: object) =>
    localStorage.setItem(key, JSON.stringify(value));

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

/**
 * Zod schema for the legacy format in which the {@link savedIsFirstLogin} and
 * {@link savedJustSignedUp} flags were saved in local storage.
 *
 * Starting 1.7.15-beta (July 2025), we started saving the booleans directly,
 * but when reading we fallback to the old format if needed. This fallback can
 * be removed, and soonish, since these are transient flags that are saved
 * during the login / signup sequence and wouldn't be expected to remain in the
 * user's local storage for long anyway. (tag: Migration).
 */
const LocalLegacyBooleanFlag = z.object({
    status: z.boolean().nullish().transform(nullToUndefined),
});

/**
 * Return `true` if it is the user's first login on this client.
 *
 * The {@link savedIsFirstLogin} flag is saved in local storage (using
 * {@link saveIsFirstLogin}) if we determine during the login flow that it a
 * fresh login on this client. If so, we
 *
 * - Generate interactive key attributes for them, and
 *
 * - Display them a special indicator post login to notify them that the first
 *   load might take extra time. At this point, we also clear the flag (the read
 *   and clear is done by the same {@link getAndClearIsFirstLogin} function).
 */
export const savedIsFirstLogin = () => {
    const jsonString = localStorage.getItem("isFirstLogin");
    if (!jsonString) return false;
    try {
        return z.boolean().parse(JSON.parse(jsonString)) ?? false;
    } catch {
        return (
            LocalLegacyBooleanFlag.parse(JSON.parse(jsonString)).status ?? false
        );
    }
};

/**
 * Save a flag in local storage to indicate that this is the user's first login
 * on this client.
 *
 * This is the setter corresponding to {@link savedIsFirstLogin}.
 */
export const saveIsFirstLogin = () => {
    localStorage.setItem("isFirstLogin", JSON.stringify({ status: true }));
};

/**
 * Get the saved value of the local storage flag that indicates that this is the
 * user' first login on this client. Also remove the flag after reading.
 *
 * The flag can be set by using {@link saveIsFirstLogin}, and can be read
 * without clearing it by using {@link savedIsFirstLogin}.
 */
export const getAndClearIsFirstLogin = () => {
    const result = savedIsFirstLogin();
    localStorage.removeItem("isFirstLogin");
    return result;
};

/**
 * Return `true` if the user created a new account on this client during the
 * current (in-progress) or just completed login / signup sequence.
 */
export const savedJustSignedUp = () => {
    const jsonString = localStorage.getItem("justSignedUp");
    if (!jsonString) return false;
    try {
        return z.boolean().parse(JSON.parse(jsonString)) ?? false;
    } catch {
        return (
            LocalLegacyBooleanFlag.parse(JSON.parse(jsonString)).status ?? false
        );
    }
};

/**
 * Save a flag in local storage to indicate that the user signed up for a
 * new Ente account during the current login / signup sequence.
 *
 * This is the setter corresponding to {@link savedJustSignedUp}.
 */
export const saveJustSignedUp = () => {
    localStorage.setItem("justSignedUp", JSON.stringify({ status: true }));
};

/**
 * Get the saved value of the local storage flag that indicates that the user just
 * signed up. Also remove the flag from local storage after reading.
 *
 * The flag can be set by using {@link saveJustSignedUp}, and can be read
 * without clearing it by using {@link savedJustSignedUp}.
 */
export const getAndClearJustSignedUp = () => {
    const result = savedJustSignedUp();
    localStorage.removeItem("justSignedUp");
    return result;
};

/**
 * Zod schema for the format in which the {@link stashReferralSource} used to
 * saved the referral source in local storage.
 *
 * Starting 1.7.15-beta (July 2025), we started saving the string directly, but
 * when reading we fallback to the old format if needed. This fallback can be
 * removed, and soonish, since these is a transient value that isn't expected to
 * remain in the user's local storage for long anyway. (tag: Migration).
 */
const LocalLegacyReferralSource = z.object({ source: z.string() });

/**
 * Save the referral source entered by the user on the signup screen in local
 * storage.
 *
 * The saved value can be retrieved post email verification using
 * {@link unstashReferralSource}.
 */
export const stashReferralSource = (referralSource: string) => {
    localStorage.setItem("referralSource", referralSource);
};

/**
 * Retrieve the previously saved referral source (using
 * {@link stashReferralSource}), returning the saved value and also clearing it
 * from local storage.
 */
export const unstashReferralSource = () => {
    const jsonString = localStorage.getItem("referralSource");
    if (!jsonString) return undefined;
    localStorage.removeItem("referralSource");
    try {
        // Try the old format first. The trim is also a legacy expectation and
        // can be removed when we remove this fallfront.
        return LocalLegacyReferralSource.parse(
            JSON.parse(jsonString),
        ).source.trim();
    } catch {
        // Otherwise try the new format.
        return jsonString;
    }
};
