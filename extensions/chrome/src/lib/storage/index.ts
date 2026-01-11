import type { Code } from "../types/code";
import type { KeyAttributes, LocalUser } from "../types/auth";

/**
 * Storage keys for session storage (cleared on browser close).
 */
const SESSION_KEYS = {
  SESSION_KEY: "sessionKey",
  MASTER_KEY: "masterKey",
  AUTHENTICATOR_KEY: "authenticatorKey",
  CODES: "codes",
  TIME_OFFSET: "timeOffset",
  IS_UNLOCKED: "isUnlocked",
} as const;

/**
 * Storage keys for local storage (persistent, encrypted data).
 */
const LOCAL_KEYS = {
  USER: "user",
  KEY_ATTRIBUTES: "keyAttributes",
  ENCRYPTED_MASTER_KEY: "encryptedMasterKey",
  LAST_SYNC_TIME: "lastSyncTime",
  // Preferences (plaintext)
  AUTO_LOCK_TIMEOUT: "autoLockTimeout",
  SHOW_PHISHING_WARNINGS: "showPhishingWarnings",
  CUSTOM_API_ENDPOINT: "customApiEndpoint",
} as const;

/**
 * Session storage operations (cleared on browser close).
 */
export const sessionStorage = {
  async get<T>(key: string): Promise<T | undefined> {
    const result = await chrome.storage.session.get(key);
    return result[key] as T | undefined;
  },

  async set<T>(key: string, value: T): Promise<void> {
    await chrome.storage.session.set({ [key]: value });
  },

  async remove(key: string): Promise<void> {
    await chrome.storage.session.remove(key);
  },

  async clear(): Promise<void> {
    await chrome.storage.session.clear();
  },

  // Typed accessors
  async getSessionKey(): Promise<string | undefined> {
    return this.get<string>(SESSION_KEYS.SESSION_KEY);
  },

  async setSessionKey(key: string): Promise<void> {
    await this.set(SESSION_KEYS.SESSION_KEY, key);
  },

  async getMasterKey(): Promise<string | undefined> {
    return this.get<string>(SESSION_KEYS.MASTER_KEY);
  },

  async setMasterKey(key: string): Promise<void> {
    await this.set(SESSION_KEYS.MASTER_KEY, key);
  },

  async getAuthenticatorKey(): Promise<string | undefined> {
    return this.get<string>(SESSION_KEYS.AUTHENTICATOR_KEY);
  },

  async setAuthenticatorKey(key: string): Promise<void> {
    await this.set(SESSION_KEYS.AUTHENTICATOR_KEY, key);
  },

  async getCodes(): Promise<Code[]> {
    return (await this.get<Code[]>(SESSION_KEYS.CODES)) ?? [];
  },

  async setCodes(codes: Code[]): Promise<void> {
    await this.set(SESSION_KEYS.CODES, codes);
  },

  async getTimeOffset(): Promise<number> {
    return (await this.get<number>(SESSION_KEYS.TIME_OFFSET)) ?? 0;
  },

  async setTimeOffset(offset: number): Promise<void> {
    await this.set(SESSION_KEYS.TIME_OFFSET, offset);
  },

  async isUnlocked(): Promise<boolean> {
    return (await this.get<boolean>(SESSION_KEYS.IS_UNLOCKED)) ?? false;
  },

  async setUnlocked(unlocked: boolean): Promise<void> {
    await this.set(SESSION_KEYS.IS_UNLOCKED, unlocked);
  },
};

/**
 * Local storage operations (persistent).
 */
export const localStorage = {
  async get<T>(key: string): Promise<T | undefined> {
    const result = await chrome.storage.local.get(key);
    return result[key] as T | undefined;
  },

  async set<T>(key: string, value: T): Promise<void> {
    await chrome.storage.local.set({ [key]: value });
  },

  async remove(key: string): Promise<void> {
    await chrome.storage.local.remove(key);
  },

  async clear(): Promise<void> {
    await chrome.storage.local.clear();
  },

  // Typed accessors
  async getUser(): Promise<LocalUser | undefined> {
    return this.get<LocalUser>(LOCAL_KEYS.USER);
  },

  async setUser(user: LocalUser): Promise<void> {
    await this.set(LOCAL_KEYS.USER, user);
  },

  async removeUser(): Promise<void> {
    await this.remove(LOCAL_KEYS.USER);
  },

  async getKeyAttributes(): Promise<KeyAttributes | undefined> {
    return this.get<KeyAttributes>(LOCAL_KEYS.KEY_ATTRIBUTES);
  },

  async setKeyAttributes(attrs: KeyAttributes): Promise<void> {
    await this.set(LOCAL_KEYS.KEY_ATTRIBUTES, attrs);
  },

  async getEncryptedMasterKey(): Promise<
    { encryptedData: string; nonce: string } | undefined
  > {
    return this.get(LOCAL_KEYS.ENCRYPTED_MASTER_KEY);
  },

  async setEncryptedMasterKey(data: {
    encryptedData: string;
    nonce: string;
  }): Promise<void> {
    await this.set(LOCAL_KEYS.ENCRYPTED_MASTER_KEY, data);
  },

  async getLastSyncTime(): Promise<number> {
    return (await this.get<number>(LOCAL_KEYS.LAST_SYNC_TIME)) ?? 0;
  },

  async setLastSyncTime(time: number): Promise<void> {
    await this.set(LOCAL_KEYS.LAST_SYNC_TIME, time);
  },

  // Preferences
  async getAutoLockTimeout(): Promise<number> {
    return (await this.get<number>(LOCAL_KEYS.AUTO_LOCK_TIMEOUT)) ?? 5; // 5 minutes default
  },

  async setAutoLockTimeout(minutes: number): Promise<void> {
    await this.set(LOCAL_KEYS.AUTO_LOCK_TIMEOUT, minutes);
  },

  async getShowPhishingWarnings(): Promise<boolean> {
    return (await this.get<boolean>(LOCAL_KEYS.SHOW_PHISHING_WARNINGS)) ?? true;
  },

  async setShowPhishingWarnings(show: boolean): Promise<void> {
    await this.set(LOCAL_KEYS.SHOW_PHISHING_WARNINGS, show);
  },

  async getCustomApiEndpoint(): Promise<string | undefined> {
    return this.get<string>(LOCAL_KEYS.CUSTOM_API_ENDPOINT);
  },

  async setCustomApiEndpoint(endpoint: string | undefined): Promise<void> {
    if (endpoint) {
      await this.set(LOCAL_KEYS.CUSTOM_API_ENDPOINT, endpoint);
    } else {
      await this.remove(LOCAL_KEYS.CUSTOM_API_ENDPOINT);
    }
  },
};

/**
 * Clear all extension data (for logout).
 */
export async function clearAllData(): Promise<void> {
  await Promise.all([sessionStorage.clear(), localStorage.clear()]);
}

/**
 * Check if user is logged in.
 */
export async function isLoggedIn(): Promise<boolean> {
  const user = await localStorage.getUser();
  return user !== undefined;
}
