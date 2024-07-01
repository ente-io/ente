import { removeKV, setKV } from "@/next/kv";
import log from "@/next/log";

export enum LS_KEYS {
    USER = "user",
    KEY_ATTRIBUTES = "keyAttributes",
    ORIGINAL_KEY_ATTRIBUTES = "originalKeyAttributes",
    SUBSCRIPTION = "subscription",
    FAMILY_DATA = "familyData",
    IS_FIRST_LOGIN = "isFirstLogin",
    JUST_SIGNED_UP = "justSignedUp",
    SHOW_BACK_BUTTON = "showBackButton",
    EXPORT = "export",
    // LOGS = "logs",
    USER_DETAILS = "userDetails",
    COLLECTION_SORT_BY = "collectionSortBy",
    THEME = "theme",
    // Moved to the new wrapper @/next/local-storage
    // LOCALE = 'locale',
    MAP_ENABLED = "mapEnabled",
    SRP_SETUP_ATTRIBUTES = "srpSetupAttributes",
    SRP_ATTRIBUTES = "srpAttributes",
    CF_PROXY_DISABLED = "cfProxyDisabled",
    REFERRAL_SOURCE = "referralSource",
}

export const setData = (key: LS_KEYS, value: object) =>
    localStorage.setItem(key, JSON.stringify(value));

export const removeData = (key: LS_KEYS) => localStorage.removeItem(key);

export const getData = (key: LS_KEYS) => {
    try {
        if (
            typeof localStorage === "undefined" ||
            typeof key === "undefined" ||
            typeof localStorage.getItem(key) === "undefined" ||
            localStorage.getItem(key) === "undefined"
        ) {
            return null;
        }
        const data = localStorage.getItem(key);
        return data && JSON.parse(data);
    } catch (e) {
        log.error(`Failed to Parse JSON for key ${key}`, e);
    }
};

export const clearData = () => localStorage.clear();

// TODO: Migrate this to `local-user.ts`, with (a) more precise optionality
// indication of the constituent fields, (b) moving any fields that need to be
// accessed from web workers to KV DB.
//
// Creating a new function here to act as a funnel point.
export const setLSUser = async (user: object) => {
    const token = user["token"];
    token && typeof token == "string"
        ? await setKV("token", token)
        : await removeKV("token");
    setData(LS_KEYS.USER, user);
};

/**
 * Update the "token" KV with the token (if any) for the given {@link user}.
 *
 * This is an internal implementation details of {@link setLSUser} and doesn't
 * need to exposed conceptually. For now though, we need to call this externally
 * at an early point in the app startup to also copy over the token into KV DB
 * for existing users.
 *
 * This was added 1 July 2024, can be removed after a while (tag: Migration).
 */
export const migrateKVToken = async (user: unknown) => {
    user &&
    typeof user == "object" &&
    "token" in user &&
    typeof user.token == "string"
        ? await setKV("token", user.token)
        : await removeKV("token");
};
