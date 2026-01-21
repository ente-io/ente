/**
 * Content script entry point.
 * Detects MFA fields and shows autofill popup.
 */
import type Browser from "webextension-polyfill";
import { browser, sendMessage } from "@shared/browser";
import type { DomainMatch, ExtensionSettings, MFAFieldDetection } from "@shared/types";
import { fillCode } from "./autofill";
import { getBestMFAField } from "./detector";
import { hidePopup, showPopup } from "./popup";
import "./styles.css";

let currentDetection: MFAFieldDetection | null = null;
let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let hasShownPopup = false;

/**
 * Send message with retry logic for MV3 service worker wake-up.
 */
async function sendMessageWithRetry<T>(
    message: Parameters<typeof sendMessage>[0],
    retries = 2
): Promise<T | null> {
    try {
        return await sendMessage<T>(message);
    } catch (error) {
        // Check if it's a connection error (service worker not ready)
        const errorMessage = error instanceof Error ? error.message : String(error);
        if (errorMessage.includes("Could not establish connection") ||
            errorMessage.includes("Receiving end does not exist")) {
            if (retries > 0) {
                // Wait a bit for service worker to wake up
                await new Promise<void>(r => setTimeout(r, 100));
                return sendMessageWithRetry<T>(message, retries - 1);
            }
            // Silently fail after retries - extension might not be ready
            return null;
        }
        throw error;
    }
}

/**
 * Check for MFA fields and show popup if matches found.
 */
const checkForMFAFields = async (): Promise<void> => {
    // Don't check again if we've already shown a popup this page load
    if (hasShownPopup) return;

    // Detect MFA fields
    const detection = getBestMFAField();
    if (!detection) return;

    currentDetection = detection;

    // Get current domain
    const domain = window.location.hostname;

    try {
        // Get matching codes from background
        const response = await sendMessageWithRetry<{
            success: boolean;
            data?: { matches: DomainMatch[]; timeOffset: number };
            error?: string;
        }>({
            type: "GET_CODES_FOR_DOMAIN",
            domain,
        });

        if (!response || !response.success || !response.data) {
            // Silently return if no response (extension not ready) or no codes
            return;
        }

        const { matches, timeOffset } = response.data;

        // Only show popup if we have matches
        if (matches.length === 0) {
            return;
        }

        // Get settings to check if notifications are enabled
        const settingsResponse = await sendMessageWithRetry<{
            success: boolean;
            data?: ExtensionSettings;
        }>({ type: "GET_SETTINGS" });

        const settings = settingsResponse?.data;
        if (settings && !settings.showNotifications) {
            return;
        }

        // Auto-fill if single match and setting enabled
        if (matches.length === 1 && settings?.autoFillSingleMatch) {
            console.log("Ente Auth: Auto-filling single match");
            const { code } = matches[0]!;
            const codesResponse = await sendMessageWithRetry<{
                success: boolean;
                data?: { codes: Array<{ id: string }>; timeOffset: number };
            }>({ type: "GET_CODES" });

            if (codesResponse?.success && codesResponse.data) {
                // Generate OTP and fill
                const { generateOTPs } = await import("@shared/otp");
                const [otp] = generateOTPs(code, timeOffset);
                if (currentDetection) {
                    fillCode(currentDetection, otp);
                }
            }
            hasShownPopup = true;
            return;
        }

        // Show popup with matches
        showPopup(matches, timeOffset, (otp: string) => {
            if (currentDetection) {
                fillCode(currentDetection, otp);
            }
        });
        hasShownPopup = true;
    } catch (error) {
        // Only log unexpected errors, not connection issues
        console.error("Ente Auth: Unexpected error", error);
    }
};

/**
 * Debounced check for MFA fields.
 */
const debouncedCheck = (): void => {
    if (debounceTimer) {
        clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(checkForMFAFields, 500);
};

/**
 * Handle messages from the background script.
 */
const handleMessage = (
    message: unknown,
    _sender: Browser.Runtime.MessageSender,
    sendResponse: (response: unknown) => void
): boolean => {
    const msg = message as { type?: string; code?: string };
    if (msg.type === "FILL_OTP" && msg.code && currentDetection) {
        fillCode(currentDetection, msg.code);
        sendResponse({ success: true });
    }
    return false;
};

/**
 * Initialize the content script.
 */
const init = (): void => {
    console.log("Ente Auth content script initialized");

    // Listen for messages from background
    browser.runtime.onMessage.addListener(
        handleMessage as Parameters<typeof browser.runtime.onMessage.addListener>[0]
    );

    // Initial check
    debouncedCheck();

    // Watch for DOM changes that might indicate new MFA fields
    const observer = new MutationObserver((mutations) => {
        // Check if any mutations might have added input fields
        const hasRelevantChanges = mutations.some((mutation) => {
            if (mutation.type === "childList") {
                return Array.from(mutation.addedNodes).some(
                    (node) =>
                        node instanceof HTMLElement &&
                        (node.tagName === "INPUT" ||
                            node.querySelector?.("input"))
                );
            }
            return false;
        });

        if (hasRelevantChanges) {
            debouncedCheck();
        }
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true,
    });

    // Also check on focus events (for SPAs that show forms dynamically)
    document.addEventListener(
        "focusin",
        (e) => {
            if (e.target instanceof HTMLInputElement && !hasShownPopup) {
                debouncedCheck();
            }
        },
        true
    );

    // Clean up popup when navigating away
    window.addEventListener("beforeunload", () => {
        hidePopup();
    });
};

// Initialize when DOM is ready
if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
} else {
    init();
}
