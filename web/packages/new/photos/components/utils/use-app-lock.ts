import {
    subscribeMainWindowBlur,
    subscribeMainWindowFocus,
} from "ente-base/electron";
import { updateSessionFromElectronSafeStorageIfNeeded } from "ente-base/session";
import { useEffect, useRef, useState } from "react";
import {
    clearAutoLockBlurSuppression,
    initAppLock,
    lock,
    refreshAppLockStateFromSession,
    shouldSuppressAutoLockOnBlur,
    type AppLockState,
} from "../../services/app-lock";

/**
 * Initialize app lock and return true once app-lock gated rendering can proceed.
 *
 * This is meant to be called once from the top-level `_app.tsx`.
 */
export const useSetupAppLock = () => {
    const [isAppLockReady, setIsAppLockReady] = useState(false);

    useEffect(() => {
        const isAppLockEnabled =
            localStorage.getItem("appLock.enabled") === "true";
        initAppLock();
        if (!isAppLockEnabled) {
            setIsAppLockReady(true);
            return;
        }

        void (async () => {
            try {
                /**
                 * The current session's master key might be already existing in the OS's safe
                 * storage, so if that is foudn then writing it to the browser sessionStorage
                 *
                 * Without this the user will have to enter the password again on every launch.
                 */
                await updateSessionFromElectronSafeStorageIfNeeded();
            } finally {
                /**
                 * The app lock config is actually persisted across sessions, and for refreshing this
                 * the user must haveMasterKeyInSession().
                 */
                refreshAppLockStateFromSession();
                setIsAppLockReady(true);
            }
        })();
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
