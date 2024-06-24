import log from "@/next/log";

export enum LS_KEYS {
    USER = "user",
    SESSION = "session",
    KEY_ATTRIBUTES = "keyAttributes",
    ORIGINAL_KEY_ATTRIBUTES = "originalKeyAttributes",
    SUBSCRIPTION = "subscription",
    FAMILY_DATA = "familyData",
    IS_FIRST_LOGIN = "isFirstLogin",
    JUST_SIGNED_UP = "justSignedUp",
    SHOW_BACK_BUTTON = "showBackButton",
    EXPORT = "export",
    THUMBNAIL_FIX_STATE = "thumbnailFixState",
    LIVE_PHOTO_INFO_SHOWN_COUNT = "livePhotoInfoShownCount",
    // LOGS = "logs",
    USER_DETAILS = "userDetails",
    COLLECTION_SORT_BY = "collectionSortBy",
    THEME = "theme",
    WAIT_TIME = "waitTime",
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
