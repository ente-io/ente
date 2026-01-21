/**
 * Browser storage abstraction.
 * Provides a unified interface for chrome.storage.local and chrome.storage.session.
 */
import { browser } from "@shared/browser";
import type {
    Code,
    ExtensionSettings,
    KeyAttributes,
    defaultSettings,
} from "@shared/types";

// Storage keys
const KEYS = {
    // Local storage (persists across sessions)
    AUTH_TOKEN: "authToken",
    KEY_ATTRIBUTES: "keyAttributes",
    SETTINGS: "settings",
    SYNC_TIMESTAMP: "syncTimestamp",
    EMAIL: "email",
    // Master key in local storage for MV3 reliability
    // (session storage is unreliable with service worker lifecycle)
    MASTER_KEY: "masterKey",
    // Session storage (cleared on browser close)
    CODES_CACHE: "codesCache",
    TIME_OFFSET: "timeOffset",
} as const;

/**
 * Local storage operations (persistent).
 */
export const localStore = {
    async get<T>(key: string): Promise<T | undefined> {
        const result = await browser.storage.local.get(key);
        return result[key] as T | undefined;
    },

    async set(key: string, value: unknown): Promise<void> {
        await browser.storage.local.set({ [key]: value });
    },

    async remove(key: string): Promise<void> {
        await browser.storage.local.remove(key);
    },

    async clear(): Promise<void> {
        await browser.storage.local.clear();
    },
};

/**
 * Session storage operations (cleared on browser close).
 * Falls back to local storage if session storage is not available.
 */
export const sessionStore = {
    async get<T>(key: string): Promise<T | undefined> {
        // Check if session storage is available (Chrome MV3)
        if (browser.storage.session) {
            const result = await browser.storage.session.get(key);
            return result[key] as T | undefined;
        }
        // Fallback to local storage for Firefox MV2
        return localStore.get<T>(`session_${key}`);
    },

    async set(key: string, value: unknown): Promise<void> {
        if (browser.storage.session) {
            await browser.storage.session.set({ [key]: value });
        } else {
            await localStore.set(`session_${key}`, value);
        }
    },

    async remove(key: string): Promise<void> {
        if (browser.storage.session) {
            await browser.storage.session.remove(key);
        } else {
            await localStore.remove(`session_${key}`);
        }
    },

    async clear(): Promise<void> {
        if (browser.storage.session) {
            await browser.storage.session.clear();
        } else {
            // Clear session-prefixed items from local storage
            const items = await browser.storage.local.get(null);
            const sessionKeys = Object.keys(items).filter((k) =>
                k.startsWith("session_")
            );
            if (sessionKeys.length > 0) {
                await browser.storage.local.remove(sessionKeys);
            }
        }
    },
};

/**
 * Auth token storage.
 */
export const authStorage = {
    async getToken(): Promise<string | undefined> {
        return localStore.get<string>(KEYS.AUTH_TOKEN);
    },

    async setToken(token: string): Promise<void> {
        await localStore.set(KEYS.AUTH_TOKEN, token);
    },

    async clearToken(): Promise<void> {
        await localStore.remove(KEYS.AUTH_TOKEN);
    },

    async getKeyAttributes(): Promise<KeyAttributes | undefined> {
        return localStore.get<KeyAttributes>(KEYS.KEY_ATTRIBUTES);
    },

    async setKeyAttributes(attrs: KeyAttributes): Promise<void> {
        await localStore.set(KEYS.KEY_ATTRIBUTES, attrs);
    },

    async clearKeyAttributes(): Promise<void> {
        await localStore.remove(KEYS.KEY_ATTRIBUTES);
    },

    async getEmail(): Promise<string | undefined> {
        return localStore.get<string>(KEYS.EMAIL);
    },

    async setEmail(email: string): Promise<void> {
        await localStore.set(KEYS.EMAIL, email);
    },

    async clearEmail(): Promise<void> {
        await localStore.remove(KEYS.EMAIL);
    },

    async getMasterKey(): Promise<string | undefined> {
        // Use local storage for reliability in MV3
        return localStore.get<string>(KEYS.MASTER_KEY);
    },

    async setMasterKey(key: string): Promise<void> {
        // Use local storage for reliability in MV3
        await localStore.set(KEYS.MASTER_KEY, key);
    },

    async clearMasterKey(): Promise<void> {
        await localStore.remove(KEYS.MASTER_KEY);
    },
};

/**
 * Codes cache storage.
 */
export const codesStorage = {
    async getCodes(): Promise<Code[] | undefined> {
        return sessionStore.get<Code[]>(KEYS.CODES_CACHE);
    },

    async setCodes(codes: Code[]): Promise<void> {
        await sessionStore.set(KEYS.CODES_CACHE, codes);
    },

    async clearCodes(): Promise<void> {
        await sessionStore.remove(KEYS.CODES_CACHE);
    },

    async getTimeOffset(): Promise<number> {
        return (await sessionStore.get<number>(KEYS.TIME_OFFSET)) ?? 0;
    },

    async setTimeOffset(offset: number): Promise<void> {
        await sessionStore.set(KEYS.TIME_OFFSET, offset);
    },

    async getSyncTimestamp(): Promise<number | undefined> {
        return localStore.get<number>(KEYS.SYNC_TIMESTAMP);
    },

    async setSyncTimestamp(timestamp: number): Promise<void> {
        await localStore.set(KEYS.SYNC_TIMESTAMP, timestamp);
    },
};

/**
 * Settings storage.
 */
export const settingsStorage = {
    async getSettings(): Promise<ExtensionSettings> {
        const stored = await localStore.get<Partial<ExtensionSettings>>(
            KEYS.SETTINGS
        );
        return {
            autofillEnabled: stored?.autofillEnabled ?? true,
            syncInterval: stored?.syncInterval ?? 5,
            customApiEndpoint: stored?.customApiEndpoint,
            theme: stored?.theme ?? "system",
        };
    },

    async setSettings(settings: Partial<ExtensionSettings>): Promise<void> {
        const current = await this.getSettings();
        await localStore.set(KEYS.SETTINGS, { ...current, ...settings });
    },

    async clearSettings(): Promise<void> {
        await localStore.remove(KEYS.SETTINGS);
    },
};

/**
 * Clear all storage on logout.
 */
export const clearAllStorage = async (): Promise<void> => {
    await sessionStore.clear();
    await localStore.clear();
};
