/**
 * @file Service for the app lock feature.
 *
 * App lock is a purely client-side feature that prevents unauthorized access to
 * the app after it has been authenticated. It supports PIN and password lock
 * types, uses Argon2id for hashing, and syncs lock state across tabs via
 * BroadcastChannel.
 *
 * See: [Note: Snapshots and useSyncExternalStore].
 */

import { deriveInteractiveKey, deriveKey } from "ente-base/crypto";
import { getKVN, getKVS, removeKV, setKV } from "ente-base/kv";
import log from "ente-base/log";
import { haveMasterKeyInSession } from "ente-base/session";

/**
 * In-memory state for the app lock feature.
 *
 * Some values are persisted to localStorage (synchronous, for cold-start reads)
 * and some to IndexedDB via KV DB (async, for tamper resistance).
 */
export interface AppLockState {
    /** Whether app lock is enabled. */
    enabled: boolean;
    /** Active lock type. */
    lockType: "pin" | "password" | "none";
    /** Whether the app is currently locked. */
    isLocked: boolean;
    /** Consecutive failed attempts in current lockout cycle. */
    invalidAttemptCount: number;
    /** Epoch ms when cooldown expires (0 = no cooldown). */
    cooldownExpiresAt: number;
    /** Auto-lock delay in milliseconds. */
    autoLockTimeMs: number;
    /** Whether to blur content when tab/window is hidden. */
    hideContentOnBlur: boolean;
}

const createDefaultState = (): AppLockState => ({
    enabled: false,
    lockType: "none",
    isLocked: false,
    invalidAttemptCount: 0,
    cooldownExpiresAt: 0,
    autoLockTimeMs: 0,
    hideContentOnBlur: false,
});

/**
 * Internal in-memory state shared by the functions in this module.
 *
 * This entire object will be reset on logout.
 */
class AppLockModuleState {
    constructor() {
        this.snapshot = createDefaultState();
    }

    /**
     * Subscriptions to {@link AppLockState} updates attached using
     * {@link appLockSubscribe}.
     */
    listeners: (() => void)[] = [];

    /**
     * Snapshot of the {@link AppLockState} returned by
     * {@link appLockSnapshot}.
     */
    snapshot: AppLockState;
}

/** State shared by the functions in this module. */
let _state = new AppLockModuleState();

/**
 * A function that can be used to subscribe to updates to {@link AppLockState}.
 *
 * See: [Note: Snapshots and useSyncExternalStore].
 */
export const appLockSubscribe = (onChange: () => void): (() => void) => {
    _state.listeners.push(onChange);
    return () => {
        _state.listeners = _state.listeners.filter((l) => l != onChange);
    };
};

/**
 * Return the last known, cached {@link AppLockState}.
 *
 * See also {@link appLockSubscribe}.
 */
export const appLockSnapshot = () => _state.snapshot;

const setSnapshot = (snapshot: AppLockState) => {
    _state.snapshot = snapshot;
    _state.listeners.forEach((l) => l());
};

// -- localStorage keys (synchronous, for cold-start reads) --

const lsKeyEnabled = "appLock.enabled";
const lsKeyLockType = "appLock.lockType";
const lsKeyAutoLockTimeMs = "appLock.autoLockTimeMs";
const lsKeyHideContentOnBlur = "appLock.hideContentOnBlur";

// -- KV DB keys (IndexedDB, async) --

const kvKeyHash = "appLock.hash";
const kvKeySalt = "appLock.salt";
const kvKeyOpsLimit = "appLock.opsLimit";
const kvKeyMemLimit = "appLock.memLimit";
const kvKeyInvalidAttempts = "appLock.invalidAttempts";
const kvKeyCooldownExpiresAt = "appLock.cooldownExpiresAt";

// -- BroadcastChannel for multi-tab sync --

const _channel = new BroadcastChannel("ente-app-lock");

_channel.onmessage = (event: MessageEvent) => {
    const data = event.data as { type: string };
    if (data.type === "lock") {
        setSnapshot({ ..._state.snapshot, isLocked: true });
    } else if (data.type === "unlock") {
        setSnapshot({
            ..._state.snapshot,
            isLocked: false,
            invalidAttemptCount: 0,
            cooldownExpiresAt: 0,
        });
    }
};

// -- Public API --

/**
 * Initialize app lock state from localStorage on cold start.
 *
 * Reads localStorage synchronously so the overlay can render immediately
 * without a flash of unlocked content. Sets isLocked = true if app lock is
 * enabled and the user is logged in.
 *
 * After the synchronous snapshot, asynchronously restores the brute-force
 * attempt count and cooldown expiry from KV DB so that a page refresh cannot
 * bypass the cooldown.
 */
export const initAppLock = () => {
    const enabled = localStorage.getItem(lsKeyEnabled) === "true";
    const lockTypeRaw = localStorage.getItem(lsKeyLockType);
    const lockType: AppLockState["lockType"] =
        lockTypeRaw === "pin" || lockTypeRaw === "password"
            ? lockTypeRaw
            : "none";
    const autoLockTimeMs = Number(
        localStorage.getItem(lsKeyAutoLockTimeMs) ?? "0",
    );
    const hideContentOnBlur =
        localStorage.getItem(lsKeyHideContentOnBlur) === "true";

    const isLocked = enabled && haveMasterKeyInSession();

    setSnapshot({
        ..._state.snapshot,
        enabled,
        lockType,
        isLocked,
        autoLockTimeMs,
        hideContentOnBlur,
    });

    // Restore brute-force state from KV DB (async) so cooldowns survive
    // page refresh.
    if (isLocked) {
        void restoreBruteForceState();
    }
};

/**
 * Restore the brute-force attempt count and cooldown expiry from KV DB into
 * the in-memory snapshot.
 *
 * Called during {@link initAppLock} to ensure that cooldown timers persist
 * across page refreshes.
 */
const restoreBruteForceState = async () => {
    try {
        const [invalidAttempts, cooldownExpiry] = await Promise.all([
            getKVN(kvKeyInvalidAttempts),
            getKVN(kvKeyCooldownExpiresAt),
        ]);

        const invalidAttemptCount = invalidAttempts ?? 0;
        const cooldownExpiresAt = cooldownExpiry ?? 0;

        // Only update if there is actually persisted brute-force state.
        if (invalidAttemptCount > 0 || cooldownExpiresAt > 0) {
            setSnapshot({
                ..._state.snapshot,
                invalidAttemptCount,
                cooldownExpiresAt,
            });
        }
    } catch (e) {
        log.error("Failed to restore brute-force state from KV DB", e);
    }
};

/**
 * Set up a PIN for app lock.
 *
 * Derives a key from the PIN using Argon2id with interactive limits, stores
 * the hash and derivation parameters in KV DB, and enables the lock.
 */
export const setupPin = async (pin: string) => {
    const derived = await deriveInteractiveKey(pin);
    await setKV(kvKeyHash, derived.key);
    await setKV(kvKeySalt, derived.salt);
    await setKV(kvKeyOpsLimit, derived.opsLimit);
    await setKV(kvKeyMemLimit, derived.memLimit);

    localStorage.setItem(lsKeyLockType, "pin");
    localStorage.setItem(lsKeyEnabled, "true");

    setSnapshot({
        ..._state.snapshot,
        enabled: true,
        lockType: "pin",
    });
};

/**
 * Set up a password for app lock.
 *
 * Same as {@link setupPin} but sets the lock type to "password".
 */
export const setupPassword = async (password: string) => {
    const derived = await deriveInteractiveKey(password);
    await setKV(kvKeyHash, derived.key);
    await setKV(kvKeySalt, derived.salt);
    await setKV(kvKeyOpsLimit, derived.opsLimit);
    await setKV(kvKeyMemLimit, derived.memLimit);

    localStorage.setItem(lsKeyLockType, "password");
    localStorage.setItem(lsKeyEnabled, "true");

    setSnapshot({
        ..._state.snapshot,
        enabled: true,
        lockType: "password",
    });
};

/**
 * The result of an unlock attempt.
 *
 * - `"success"` - The input was correct; the app is now unlocked.
 * - `"failed"` - The input was incorrect.
 * - `"cooldown"` - Too many recent attempts; currently in cooldown.
 * - `"logout"` - Too many total attempts (>= 10); caller should force logout.
 */
export type UnlockResult = "success" | "failed" | "cooldown" | "logout";

/**
 * Attempt to unlock the app with the given PIN or password.
 *
 * Implements brute-force protection: after 5 failed attempts, a cooldown
 * period is enforced (exponential backoff starting at 30s). After 10 failed
 * attempts, signals that the caller should force-logout the user.
 */
export const attemptUnlock = async (input: string): Promise<UnlockResult> => {
    // Check cooldown from in-memory state.
    if (
        _state.snapshot.cooldownExpiresAt > 0 &&
        Date.now() < _state.snapshot.cooldownExpiresAt
    ) {
        return "cooldown";
    }

    // Read stored derivation parameters and hash from KV DB.
    const salt = await getKVS(kvKeySalt);
    const storedHash = await getKVS(kvKeyHash);
    const opsLimit = await getKVN(kvKeyOpsLimit);
    const memLimit = await getKVN(kvKeyMemLimit);

    if (!salt || !storedHash || !opsLimit || !memLimit) {
        log.error("App lock credentials missing from KV DB");
        return "failed";
    }

    // Derive key from input using the stored parameters.
    const derivedKey = await deriveKey(input, salt, opsLimit, memLimit);

    if (derivedKey === storedHash) {
        // Correct input: reset attempts, unlock.
        await setKV(kvKeyInvalidAttempts, 0);
        await setKV(kvKeyCooldownExpiresAt, 0);

        setSnapshot({
            ..._state.snapshot,
            isLocked: false,
            invalidAttemptCount: 0,
            cooldownExpiresAt: 0,
        });

        _channel.postMessage({ type: "unlock" });
        return "success";
    }

    // Incorrect input: increment attempts.
    const count = _state.snapshot.invalidAttemptCount + 1;
    await setKV(kvKeyInvalidAttempts, count);

    if (count >= 10) {
        // Too many attempts: signal logout.
        await setKV(kvKeyCooldownExpiresAt, 0);
        setSnapshot({
            ..._state.snapshot,
            invalidAttemptCount: count,
            cooldownExpiresAt: 0,
        });
        return "logout";
    }

    if (count >= 5) {
        // Enforce cooldown with exponential backoff.
        const cooldownSeconds = Math.pow(2, count - 5) * 30;
        const expiresAt = Date.now() + cooldownSeconds * 1000;
        await setKV(kvKeyCooldownExpiresAt, expiresAt);

        setSnapshot({
            ..._state.snapshot,
            invalidAttemptCount: count,
            cooldownExpiresAt: expiresAt,
        });

        // The current failed attempt has triggered cooldown, so surface the
        // cooldown state immediately to callers/UI.
        return "cooldown";
    } else {
        setSnapshot({
            ..._state.snapshot,
            invalidAttemptCount: count,
        });
    }

    return "failed";
};

/**
 * Lock the app and broadcast to other tabs.
 */
export const lock = () => {
    setSnapshot({ ..._state.snapshot, isLocked: true });
    _channel.postMessage({ type: "lock" });
};

/**
 * Clear all app lock data on logout.
 *
 * Removes all localStorage and KV DB keys, and resets in-memory state to
 * defaults.
 */
export const logoutAppLock = async () => {
    localStorage.removeItem(lsKeyEnabled);
    localStorage.removeItem(lsKeyLockType);
    localStorage.removeItem(lsKeyAutoLockTimeMs);
    localStorage.removeItem(lsKeyHideContentOnBlur);

    await removeKV(kvKeyHash);
    await removeKV(kvKeySalt);
    await removeKV(kvKeyOpsLimit);
    await removeKV(kvKeyMemLimit);
    await removeKV(kvKeyInvalidAttempts);
    await removeKV(kvKeyCooldownExpiresAt);

    _state = new AppLockModuleState();
};

/**
 * Update the auto-lock delay.
 */
export const setAutoLockTime = (ms: number) => {
    localStorage.setItem(lsKeyAutoLockTimeMs, String(ms));
    setSnapshot({ ..._state.snapshot, autoLockTimeMs: ms });
};

/**
 * Update the hide-content-on-blur preference.
 */
export const setHideContentOnBlur = (enabled: boolean) => {
    if (enabled) {
        localStorage.setItem(lsKeyHideContentOnBlur, "true");
    } else {
        localStorage.removeItem(lsKeyHideContentOnBlur);
    }
    setSnapshot({ ..._state.snapshot, hideContentOnBlur: enabled });
};

/**
 * Disable app lock entirely.
 *
 * Clears the stored hash, salt, and derivation parameters from KV DB, resets
 * attempts and cooldown, and updates localStorage and in-memory state.
 */
export const disableAppLock = async () => {
    await removeKV(kvKeyHash);
    await removeKV(kvKeySalt);
    await removeKV(kvKeyOpsLimit);
    await removeKV(kvKeyMemLimit);
    await removeKV(kvKeyInvalidAttempts);
    await removeKV(kvKeyCooldownExpiresAt);

    localStorage.setItem(lsKeyEnabled, "false");
    localStorage.removeItem(lsKeyLockType);

    setSnapshot({
        ..._state.snapshot,
        enabled: false,
        lockType: "none",
        isLocked: false,
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
};
