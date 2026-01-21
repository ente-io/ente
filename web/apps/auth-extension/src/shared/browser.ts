/**
 * Browser API abstraction using webextension-polyfill.
 * Normalizes Chrome/Firefox APIs into a unified Promise-based interface.
 */
import Browser from "webextension-polyfill";

export const browser = Browser;

/**
 * Check if we're running in a Chrome environment.
 */
export const isChrome = (): boolean => {
    return (
        typeof globalThis !== "undefined" &&
        "chrome" in globalThis &&
        typeof (globalThis as { chrome?: { runtime?: { getManifest?: () => { manifest_version?: number } } } }).chrome?.runtime?.getManifest === "function" &&
        (globalThis as { chrome?: { runtime?: { getManifest?: () => { manifest_version?: number } } } }).chrome?.runtime?.getManifest?.()?.manifest_version === 3
    );
};

/**
 * Check if we're running in a Firefox environment.
 */
export const isFirefox = (): boolean => {
    return typeof browser.runtime.getBrowserInfo === "function";
};

/**
 * Get the current active tab.
 */
export const getCurrentTab = async (): Promise<Browser.Tabs.Tab | undefined> => {
    const tabs = await browser.tabs.query({ active: true, currentWindow: true });
    return tabs[0];
};

/**
 * Send a message to the background script.
 */
export const sendMessage = async <T>(message: unknown): Promise<T> => {
    return browser.runtime.sendMessage(message) as Promise<T>;
};

/**
 * Send a message to a content script in a specific tab.
 */
export const sendTabMessage = async <T>(
    tabId: number,
    message: unknown
): Promise<T> => {
    return browser.tabs.sendMessage(tabId, message) as Promise<T>;
};

/**
 * Create an alarm for periodic sync.
 */
export const createAlarm = async (
    name: string,
    periodInMinutes: number
): Promise<void> => {
    await browser.alarms.create(name, { periodInMinutes });
};

/**
 * Clear an alarm.
 */
export const clearAlarm = async (name: string): Promise<boolean> => {
    return browser.alarms.clear(name);
};

/**
 * Add an alarm listener.
 */
export const onAlarm = (
    callback: (alarm: Browser.Alarms.Alarm) => void
): void => {
    browser.alarms.onAlarm.addListener(callback);
};

/**
 * Message listener callback type.
 */
type MessageCallback = (
    message: unknown,
    sender: Browser.Runtime.MessageSender,
    sendResponse: (response: unknown) => void
) => boolean | void | Promise<unknown>;

/**
 * Add a message listener.
 */
export const onMessage = (callback: MessageCallback): void => {
    browser.runtime.onMessage.addListener(
        callback as Parameters<typeof browser.runtime.onMessage.addListener>[0]
    );
};

/**
 * Open the extension options page.
 */
export const openOptionsPage = async (): Promise<void> => {
    await browser.runtime.openOptionsPage();
};

/**
 * Open a URL in a new tab.
 */
export const openTab = async (url: string): Promise<Browser.Tabs.Tab> => {
    return browser.tabs.create({ url });
};
