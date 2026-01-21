/**
 * Background script entry point.
 * Handles message passing, alarms, and extension lifecycle.
 */
import type Browser from "webextension-polyfill";
import { browser, createAlarm, onAlarm, onMessage } from "@shared/browser";
import { matchCodesToDomain } from "@shared/domain-matcher";
import { deriveKey, decryptBoxBytes, toB64 } from "@shared/crypto";
import type {
    ExtensionMessage,
    ExtensionResponse,
    WebLoginCredentials,
} from "@shared/types";
import { getAuthState, login, logout, unlock } from "./auth";
import { settingsStorage, authStorage } from "./storage";
import { getCodes, getTimeOffset, syncCodes } from "./sync";

const SYNC_ALARM_NAME = "ente-auth-sync";

/**
 * Initialize the background script.
 */
const init = async () => {
    console.log("Ente Auth extension background script initialized");

    // Set up periodic sync alarm
    const settings = await settingsStorage.getSettings();
    await createAlarm(SYNC_ALARM_NAME, settings.syncInterval);

    // Handle alarm events
    onAlarm(async (alarm) => {
        if (alarm.name === SYNC_ALARM_NAME) {
            console.log("Sync alarm triggered");
            try {
                await syncCodes();
            } catch (e) {
                console.error("Sync alarm failed:", e);
            }
        }
    });

    // Handle messages from popup and content scripts
    onMessage((message, sender, sendResponse) => {
        handleMessage(message as ExtensionMessage, sender)
            .then(sendResponse)
            .catch((error) => {
                console.error("Message handler error:", error);
                sendResponse({ success: false, error: error.message });
            });
        return true; // Keep message channel open for async response
    });
};

/**
 * Handle incoming messages.
 */
const handleMessage = async (
    message: ExtensionMessage,
    _sender: Browser.Runtime.MessageSender
): Promise<ExtensionResponse> => {
    switch (message.type) {
        case "GET_AUTH_STATE": {
            const state = await getAuthState();
            return { success: true, data: state };
        }

        case "LOGIN": {
            try {
                // In a real implementation, this would be called from the auth.ente.io callback
                // For now, we expect token and keyAttributes to be passed directly
                await login(message.token, message.keyAttributes, "");
                return { success: true };
            } catch (e) {
                return {
                    success: false,
                    error: e instanceof Error ? e.message : "Login failed",
                };
            }
        }

        case "LOGIN_SRP": {
            // Deprecated: Use OPEN_WEB_LOGIN instead
            return {
                success: false,
                error: "Please use the web login option instead.",
            };
        }

        case "OPEN_WEB_LOGIN": {
            try {
                // Open auth.ente.io in a new tab for the user to log in
                const settings = await settingsStorage.getSettings();
                const baseUrl = settings.customApiEndpoint
                    ? settings.customApiEndpoint.replace("/api", "")
                    : "https://auth.ente.io";
                await browser.tabs.create({ url: baseUrl });
                return { success: true };
            } catch (e) {
                return {
                    success: false,
                    error: e instanceof Error ? e.message : "Failed to open login page",
                };
            }
        }

        case "WEB_LOGIN_CREDENTIALS": {
            try {
                const credentials = message.credentials as WebLoginCredentials;
                console.log("Received web login credentials for:", credentials.email);
                console.log("Has masterKey:", !!credentials.masterKey);
                console.log("Has password:", !!credentials.password);

                // Store credentials
                await login(credentials.token, credentials.keyAttributes, credentials.email);

                // Get master key - prefer the one from session storage (already decrypted)
                let masterKey = credentials.masterKey;

                // Only try password derivation if we don't have masterKey
                if (!masterKey && credentials.password) {
                    console.log("Deriving master key from password...");
                    // Derive KEK from password
                    const kek = await deriveKey(
                        credentials.password,
                        credentials.keyAttributes.kekSalt,
                        credentials.keyAttributes.opsLimit,
                        credentials.keyAttributes.memLimit
                    );
                    // Decrypt master key using KEK
                    const masterKeyBytes = await decryptBoxBytes(
                        {
                            encryptedData: credentials.keyAttributes.encryptedKey,
                            nonce: credentials.keyAttributes.keyDecryptionNonce,
                        },
                        kek
                    );
                    masterKey = await toB64(masterKeyBytes);
                }

                if (masterKey) {
                    await authStorage.setMasterKey(masterKey);

                    // Sync codes after successful login
                    try {
                        await syncCodes();
                    } catch (syncError) {
                        console.error("Failed to sync after login:", syncError);
                    }
                    return { success: true };
                } else {
                    console.log("No master key available, user will need to unlock");
                    return { success: false, error: "No master key - please unlock manually" };
                }
            } catch (e) {
                console.error("Web login error:", e);
                return {
                    success: false,
                    error: e instanceof Error ? e.message : "Login failed",
                };
            }
        }

        case "UNLOCK": {
            try {
                const success = await unlock(message.password);
                if (success) {
                    // Sync codes after unlocking
                    await syncCodes();
                    return { success: true };
                }
                return { success: false, error: "Invalid password" };
            } catch (e) {
                return {
                    success: false,
                    error:
                        e instanceof Error ? e.message : "Failed to unlock",
                };
            }
        }

        case "LOGOUT": {
            await logout();
            return { success: true };
        }

        case "GET_CODES": {
            const codes = await getCodes();
            const timeOffset = await getTimeOffset();
            return { success: true, data: { codes, timeOffset } };
        }

        case "GET_CODES_FOR_DOMAIN": {
            const codes = await getCodes();
            const matches = matchCodesToDomain(codes, message.domain);
            const timeOffset = await getTimeOffset();
            return { success: true, data: { matches, timeOffset } };
        }

        case "SYNC_CODES": {
            try {
                const codes = await syncCodes();
                return { success: true, data: { codesCount: codes.length } };
            } catch (e) {
                return {
                    success: false,
                    error: e instanceof Error ? e.message : "Sync failed",
                };
            }
        }

        case "GET_SETTINGS": {
            const settings = await settingsStorage.getSettings();
            return { success: true, data: settings };
        }

        case "SET_SETTINGS": {
            await settingsStorage.setSettings(message.settings);
            // Update sync alarm if interval changed
            if (message.settings.syncInterval !== undefined) {
                await createAlarm(SYNC_ALARM_NAME, message.settings.syncInterval);
            }
            return { success: true };
        }

        case "FILL_CODE": {
            // Send the code to the content script in the specified tab
            if (message.tabId) {
                await browser.tabs.sendMessage(message.tabId, {
                    type: "FILL_OTP",
                    code: message.code,
                });
            }
            return { success: true };
        }

        default:
            return { success: false, error: "Unknown message type" };
    }
};

// Initialize when the script loads
init();
