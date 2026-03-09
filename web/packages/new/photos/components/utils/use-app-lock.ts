import {
    subscribeMainWindowBlur,
    subscribeMainWindowFocus,
} from "ente-base/electron";
import log from "ente-base/log";
import { updateSessionFromElectronSafeStorageIfNeeded } from "ente-base/session";
import { useEffect, useRef, useState } from "react";
import {
    appLockSnapshot,
    clearAutoLockBlurSuppression,
    initAppLock,
    lock,
    refreshAppLockStateFromSession,
    shouldSuppressAutoLockOnBlur,
    type AppLockState,
} from "../../services/app-lock";

const hydrateSessionFromSafeStorageIfNeeded = async () => {
    try {
        /**
         * The current session's master key might already exist in the OS's safe
         * storage, so if found then write it back into browser sessionStorage.
         *
         * Without this the user would need to re-enter the password on every
         * desktop launch.
         */
        await updateSessionFromElectronSafeStorageIfNeeded();
    } catch (e) {
        log.warn(
            "Failed to hydrate session from Electron safe storage during app lock bootstrap",
            e,
        );
    }
};

const refreshBootstrapAppLockState = async () => {
    try {
        /**
         * The app lock config is persisted across sessions, and refreshing it
         * here recomputes the lock state after session hydration.
         */
        await refreshAppLockStateFromSession();
    } catch (e) {
        log.error("Failed to refresh app lock state during bootstrap", e);
    }
};

const bootstrapAppLock = async () => {
    try {
        await initAppLock();
    } catch (e) {
        log.error("Failed to initialize app lock during bootstrap", e);
        return;
    }

    if (!appLockSnapshot().enabled) {
        return;
    }

    await hydrateSessionFromSafeStorageIfNeeded();
    await refreshBootstrapAppLockState();
};

/**
 * Initialize app lock and return true once app-lock gated rendering can proceed.
 *
 * This is meant to be called once from the top-level `_app.tsx`.
 */
export const useSetupAppLock = () => {
    const [isAppLockReady, setIsAppLockReady] = useState(false);
    const didCancelRef = useRef(false);

    useEffect(() => {
        didCancelRef.current = false;

        void (async () => {
            try {
                await bootstrapAppLock();
            } finally {
                if (!didCancelRef.current) {
                    setIsAppLockReady(true);
                }
            }
        })();

        return () => {
            didCancelRef.current = true;
        };
    }, []);

    return isAppLockReady;
};

/**
 * Start and clear auto-lock timers as the app moves between background and
 * foreground states.
 */
export const useAutoLockWhenBackgrounded = (
    enabled: AppLockState["enabled"],
    isLocked: AppLockState["isLocked"],
    autoLockTimeMs: AppLockState["autoLockTimeMs"],
) => {
    // Holds the current timeout handle for a scheduled auto-lock.
    const pendingAutoLockTimeoutRef = useRef<ReturnType<
        typeof setTimeout
    > | null>(null);
    // Stores the exact timestamp when auto-lock should happen.
    const autoLockDueAtTimestampRef = useRef<number | null>(null);

    useEffect(() => {
        if (!enabled) return;

        const clearAutoLockTimer = () => {
            if (pendingAutoLockTimeoutRef.current) {
                clearTimeout(pendingAutoLockTimeoutRef.current);
                pendingAutoLockTimeoutRef.current = null;
            }
            autoLockDueAtTimestampRef.current = null;
        };

        const lockIfDeadlineElapsed = () => {
            // Return early if the lock deadline has not been reached yet.
            // If the deadline has passed, clear timer state and lock now.
            const deadline = autoLockDueAtTimestampRef.current;
            if (deadline === null) return false;
            if (Date.now() < deadline) return false;

            clearAutoLockTimer();
            lock();
            return true;
        };

        // Called when the app is backgrounded.
        // Starts auto-lock unless the app is already locked.
        const startAutoLockTimer = () => {
            if (isLocked) return;
            if (shouldSuppressAutoLockOnBlur()) return;

            const existingDeadline = autoLockDueAtTimestampRef.current;
            if (existingDeadline !== null && Date.now() < existingDeadline) {
                return;
            }

            if (autoLockTimeMs <= 0) {
                clearAutoLockTimer();
                lock();
                return;
            }

            if (pendingAutoLockTimeoutRef.current) {
                clearTimeout(pendingAutoLockTimeoutRef.current);
            }
            autoLockDueAtTimestampRef.current = Date.now() + autoLockTimeMs;
            pendingAutoLockTimeoutRef.current = setTimeout(() => {
                autoLockDueAtTimestampRef.current = null;
                lock();
            }, autoLockTimeMs);
        };

        // On foreground, lock immediately if the deadline passed; otherwise clear pending timer.
        const handleAppForegrounded = () => {
            clearAutoLockBlurSuppression();
            if (lockIfDeadlineElapsed()) return;
            clearAutoLockTimer();
        };

        // Hidden means backgrounded, so start auto-lock countdown.
        // Visible means foregrounded, so re-check deadline and clear timer if needed.
        const handleVisibilityChange = () => {
            if (document.hidden) {
                startAutoLockTimer();
            } else {
                handleAppForegrounded();
            }
        };

        const handleWindowFocus = () => {
            handleAppForegrounded();
        };

        let unsubscribeMainWindowFocus: (() => void) | undefined;
        let unsubscribeMainWindowBlur: (() => void) | undefined;
        if (globalThis.electron) {
            unsubscribeMainWindowFocus = subscribeMainWindowFocus(
                handleAppForegrounded,
            );
            unsubscribeMainWindowBlur =
                subscribeMainWindowBlur(startAutoLockTimer);
        }

        document.addEventListener("visibilitychange", handleVisibilityChange);
        window.addEventListener("focus", handleWindowFocus);

        // cleanup
        return () => {
            document.removeEventListener(
                "visibilitychange",
                handleVisibilityChange,
            );
            window.removeEventListener("focus", handleWindowFocus);
            unsubscribeMainWindowFocus?.();
            unsubscribeMainWindowBlur?.();
            clearAutoLockTimer();
        };
    }, [enabled, isLocked, autoLockTimeMs]);
};
