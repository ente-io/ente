/**
 * @file Service for the app lock feature.
 *
 * App lock is a purely client-side feature that prevents unauthorized access to
 * the app after it has been authenticated. It supports PIN, password, and
 * local WebAuthn device lock types, uses Argon2id for passphrase hashing, and
 * syncs lock state across tabs via BroadcastChannel.
 *
 * See: [Note: Snapshots and useSyncExternalStore].
 */

import {
    deriveInteractiveKey,
    deriveKey,
    fromB64URLSafeNoPadding,
    toB64URLSafeNoPadding,
} from "ente-base/crypto";
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
    /** Active passphrase lock type. */
    lockType: "pin" | "password" | "none";
    /** Whether local WebAuthn device lock is enabled. */
    deviceLockEnabled: boolean;
    /** Whether the app is currently locked. */
    isLocked: boolean;
    /** Consecutive failed attempts in current lockout cycle. */
    invalidAttemptCount: number;
    /** Epoch ms when cooldown expires (0 = no cooldown). */
    cooldownExpiresAt: number;
    /** Auto-lock delay in milliseconds. */
    autoLockTimeMs: number;
}

const createDefaultState = (): AppLockState => ({
    enabled: false,
    lockType: "none",
    deviceLockEnabled: false,
    isLocked: false,
    invalidAttemptCount: 0,
    cooldownExpiresAt: 0,
    autoLockTimeMs: 0,
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
let _bruteForceStateHydration = Promise.resolve();
let _bruteForceStateHydrationGeneration = 0;

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
const lsKeyDeviceLockEnabled = "appLock.deviceLockEnabled";
const lsKeyAutoLockTimeMs = "appLock.autoLockTimeMs";

// -- KV DB keys (IndexedDB, async) --

const kvKeyHash = "appLock.hash";
const kvKeySalt = "appLock.salt";
const kvKeyOpsLimit = "appLock.opsLimit";
const kvKeyMemLimit = "appLock.memLimit";
const kvKeyInvalidAttempts = "appLock.invalidAttempts";
const kvKeyCooldownExpiresAt = "appLock.cooldownExpiresAt";
const kvKeyWebAuthnCredentialID = "appLock.webAuthnCredentialID";

// -- WebAuthn constants --

const webAuthnTimeoutMs = 60_000;
const webAuthnChallengeBytes = 32;
const userVerifiedFlag = 0x04;
const deviceLockEnablePromptReason = "Enable device lock for Ente";
const deviceLockUnlockPromptReason = "Unlock Ente";

// -- BroadcastChannel for multi-tab sync --

const _channel = new BroadcastChannel("ente-app-lock");

_channel.onmessage = (event: MessageEvent) => {
    const data = event.data as { type: string };
    if (data.type === "lock") {
        setSnapshot({ ..._state.snapshot, isLocked: true });
        hydrateBruteForceStateIfNeeded();
    } else if (data.type === "unlock") {
        setSnapshot({
            ..._state.snapshot,
            isLocked: false,
            invalidAttemptCount: 0,
            cooldownExpiresAt: 0,
        });
        stopBruteForceStateHydration();
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
    const hasPassphraseLockType =
        lockTypeRaw === "pin" || lockTypeRaw === "password";
    const hasLegacyDeviceLockType =
        lockTypeRaw === "biometric" || lockTypeRaw === "deviceLock";
    const hasDeviceLockFlag =
        localStorage.getItem(lsKeyDeviceLockEnabled) === "true";
    const lockType: AppLockState["lockType"] = hasPassphraseLockType
        ? lockTypeRaw
        : "none";
    const deviceLockEnabled = hasDeviceLockFlag || hasLegacyDeviceLockType;
    const autoLockTimeMs = Number(
        localStorage.getItem(lsKeyAutoLockTimeMs) ?? "0",
    );

    if (hasLegacyDeviceLockType) {
        localStorage.setItem(lsKeyDeviceLockEnabled, "true");
        localStorage.removeItem(lsKeyLockType);
    }

    // Remove stale key from removed "hide content when switching apps" setting.
    localStorage.removeItem("appLock.hideContentOnBlur");

    const isLocked = enabled && haveMasterKeyInSession();

    setSnapshot({
        ..._state.snapshot,
        enabled,
        lockType,
        deviceLockEnabled,
        isLocked,
        autoLockTimeMs,
    });

    // Restore brute-force state from KV DB so cooldowns survive page refresh.
    hydrateBruteForceStateIfNeeded();
};

/**
 * Restore the brute-force attempt count and cooldown expiry from KV DB into
 * the in-memory snapshot.
 *
 * Called during {@link initAppLock} to ensure that cooldown timers persist
 * across page refreshes.
 */
const restoreBruteForceState = async (generation: number) => {
    try {
        const [invalidAttempts, cooldownExpiry] = await Promise.all([
            getKVN(kvKeyInvalidAttempts),
            getKVN(kvKeyCooldownExpiresAt),
        ]);

        if (generation !== _bruteForceStateHydrationGeneration) {
            return;
        }

        const invalidAttemptCount = invalidAttempts ?? 0;
        const cooldownExpiresAt = cooldownExpiry ?? 0;

        if (
            _state.snapshot.invalidAttemptCount !== invalidAttemptCount ||
            _state.snapshot.cooldownExpiresAt !== cooldownExpiresAt
        ) {
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

const stopBruteForceStateHydration = () => {
    _bruteForceStateHydrationGeneration += 1;
    _bruteForceStateHydration = Promise.resolve();
};

const hydrateBruteForceStateIfNeeded = () => {
    if (!_state.snapshot.isLocked || _state.snapshot.lockType === "none") {
        stopBruteForceStateHydration();
        return;
    }

    const generation = ++_bruteForceStateHydrationGeneration;
    _bruteForceStateHydration = restoreBruteForceState(generation);
};

const ensureBruteForceStateHydrated = async () => {
    await _bruteForceStateHydration;
};

const hasWebAuthnSupport = () =>
    (() => {
        if (
            typeof window == "undefined" ||
            !window.isSecureContext ||
            typeof PublicKeyCredential == "undefined"
        ) {
            return false;
        }

        const credentials: CredentialsContainer | undefined =
            "credentials" in navigator ? navigator.credentials : undefined;

        return typeof credentials != "undefined";
    })();

/**
 * Return true if the current environment can use a platform authenticator for
 * local device lock app unlocks.
 */
export const isDeviceLockSupported = async () => {
    if (globalThis.electron) {
        try {
            const nativeSupported =
                await globalThis.electron.isDeviceLockSupported();
            if (nativeSupported) return true;
        } catch (e) {
            log.warn("Failed to query native device lock support", e);
        }
    }

    if (!hasWebAuthnSupport()) return false;

    if (
        typeof PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable !=
        "function"
    ) {
        return true;
    }

    try {
        return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
    } catch (e) {
        log.warn("Failed to query platform authenticator availability", e);
        return false;
    }
};

const randomBytes = (length: number) => {
    const bytes = new Uint8Array(length);
    crypto.getRandomValues(bytes);
    return bytes;
};

const normalizeB64URLNoPadding = (value: string) =>
    value.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

const parseClientDataJSON = (clientDataJSON: ArrayBuffer) => {
    try {
        const json = new TextDecoder().decode(clientDataJSON);
        return JSON.parse(json) as {
            type?: string;
            challenge?: string;
            origin?: string;
        };
    } catch (e) {
        log.error("Failed to parse WebAuthn clientDataJSON", e);
        return undefined;
    }
};

const isUserVerified = (authenticatorData: ArrayBuffer) => {
    const data = new Uint8Array(authenticatorData);
    const flagsOffset = 32;
    if (data.length <= flagsOffset) return false;
    const flags = data[flagsOffset] ?? 0;
    return (flags & userVerifiedFlag) !== 0;
};

const clearPassphraseMaterial = async () =>
    Promise.all([
        removeKV(kvKeyHash),
        removeKV(kvKeySalt),
        removeKV(kvKeyOpsLimit),
        removeKV(kvKeyMemLimit),
    ]);

const resetBruteForceState = async () =>
    Promise.all([
        setKV(kvKeyInvalidAttempts, 0),
        setKV(kvKeyCooldownExpiresAt, 0),
    ]);

const unlockLocally = () => {
    setSnapshot({
        ..._state.snapshot,
        isLocked: false,
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
    _channel.postMessage({ type: "unlock" });
};

/**
 * Recompute and refresh whether the app should currently be locked based on
 * session availability.
 *
 * Call this after desktop safe-storage restore to prevent auto-login bypass.
 */
export const refreshAppLockStateFromSession = () => {
    initAppLock();
};

/**
 * The result of a device lock setup attempt.
 *
 * - `"success"` - Device lock setup completed and app lock configured.
 * - `"not-supported"` - Platform authenticator is not available.
 * - `"failed"` - Setup failed or was cancelled.
 */
export type SetupDeviceLockResult = "success" | "not-supported" | "failed";

/**
 * Set up a PIN for app lock.
 *
 * Derives a key from the PIN using Argon2id with interactive limits, stores
 * the hash and derivation parameters in KV DB, and enables the lock.
 */
export const setupPin = async (pin: string) => {
    const derived = await deriveInteractiveKey(pin);
    await Promise.all([
        setKV(kvKeyHash, derived.key),
        setKV(kvKeySalt, derived.salt),
        setKV(kvKeyOpsLimit, derived.opsLimit),
        setKV(kvKeyMemLimit, derived.memLimit),
        resetBruteForceState(),
    ]);

    localStorage.setItem(lsKeyLockType, "pin");
    localStorage.setItem(lsKeyEnabled, "true");

    setSnapshot({
        ..._state.snapshot,
        enabled: true,
        lockType: "pin",
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
};

/**
 * Set up a password for app lock.
 *
 * Same as {@link setupPin} but sets the lock type to "password".
 */
export const setupPassword = async (password: string) => {
    const derived = await deriveInteractiveKey(password);
    await Promise.all([
        setKV(kvKeyHash, derived.key),
        setKV(kvKeySalt, derived.salt),
        setKV(kvKeyOpsLimit, derived.opsLimit),
        setKV(kvKeyMemLimit, derived.memLimit),
        resetBruteForceState(),
    ]);

    localStorage.setItem(lsKeyLockType, "password");
    localStorage.setItem(lsKeyEnabled, "true");

    setSnapshot({
        ..._state.snapshot,
        enabled: true,
        lockType: "password",
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
};

/**
 * Set up local WebAuthn device lock authentication for app lock.
 *
 * On desktop Electron, this first tries native OS authentication; if that's
 * unavailable, it falls back to a local WebAuthn credential flow.
 *
 * The WebAuthn fallback creates a platform credential locally using
 * `navigator.credentials` without any backend ceremony. The created credential
 * ID is stored in KV DB and used for future local unlock requests.
 */
export const setupDeviceLock = async (): Promise<SetupDeviceLockResult> => {
    try {
        if (globalThis.electron) {
            try {
                const nativeSupported =
                    await globalThis.electron.isDeviceLockSupported();
                if (nativeSupported) {
                    const unlocked = await globalThis.electron.promptDeviceLock(
                        deviceLockEnablePromptReason,
                    );
                    if (!unlocked) return "failed";

                    await resetBruteForceState();

                    localStorage.setItem(lsKeyDeviceLockEnabled, "true");
                    localStorage.setItem(lsKeyEnabled, "true");

                    setSnapshot({
                        ..._state.snapshot,
                        enabled: true,
                        deviceLockEnabled: true,
                        invalidAttemptCount: 0,
                        cooldownExpiresAt: 0,
                    });
                    stopBruteForceStateHydration();

                    return "success";
                }
            } catch (e) {
                log.warn(
                    "Native device lock setup unavailable, trying WebAuthn fallback",
                    e,
                );
            }
        }

        if (!hasWebAuthnSupport()) {
            return "not-supported";
        }

        const challenge = randomBytes(webAuthnChallengeBytes);
        const userID = randomBytes(webAuthnChallengeBytes);

        const credential = (await navigator.credentials.create({
            publicKey: {
                challenge,
                rp: { name: "Ente Photos App Lock" },
                user: {
                    id: userID,
                    name: "ente-app-lock",
                    displayName: "Ente App Lock",
                },
                pubKeyCredParams: [
                    { type: "public-key", alg: -7 },
                    { type: "public-key", alg: -257 },
                ],
                authenticatorSelection: {
                    authenticatorAttachment: "platform",
                    userVerification: "required",
                },
                timeout: webAuthnTimeoutMs,
                attestation: "none",
            },
        })) as PublicKeyCredential | null;

        if (!credential) {
            return "failed";
        }

        const credentialID = await toB64URLSafeNoPadding(
            new Uint8Array(credential.rawId),
        );

        await Promise.all([
            setKV(kvKeyWebAuthnCredentialID, credentialID),
            resetBruteForceState(),
        ]);

        localStorage.setItem(lsKeyDeviceLockEnabled, "true");
        localStorage.setItem(lsKeyEnabled, "true");

        setSnapshot({
            ..._state.snapshot,
            enabled: true,
            deviceLockEnabled: true,
            invalidAttemptCount: 0,
            cooldownExpiresAt: 0,
        });
        stopBruteForceStateHydration();

        return "success";
    } catch (e) {
        log.error("Failed to set up device lock app lock", e);
        return "failed";
    }
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
 * The result of a device lock unlock attempt.
 */
export type DeviceLockUnlockResult = "success" | "failed" | "not-supported";

/**
 * Attempt to unlock the app with a local WebAuthn device lock check.
 *
 * This is a fully local verification flow and does not call any backend API.
 */
export const attemptDeviceLockUnlock =
    async (): Promise<DeviceLockUnlockResult> => {
        if (globalThis.electron) {
            try {
                const nativeSupported =
                    await globalThis.electron.isDeviceLockSupported();
                if (nativeSupported) {
                    const unlocked = await globalThis.electron.promptDeviceLock(
                        deviceLockUnlockPromptReason,
                    );
                    if (!unlocked) return "failed";

                    await resetBruteForceState();
                    unlockLocally();
                    return "success";
                }
            } catch (e) {
                log.warn(
                    "Native device lock unlock unavailable, trying WebAuthn fallback",
                    e,
                );
            }
        }

        if (!hasWebAuthnSupport()) {
            return "not-supported";
        }

        const storedCredentialID = await getKVS(kvKeyWebAuthnCredentialID);
        if (!storedCredentialID) {
            log.error("Device lock app lock credential missing from KV DB");
            return "failed";
        }

        try {
            const challengeBytes = randomBytes(webAuthnChallengeBytes);
            const challengeB64 = await toB64URLSafeNoPadding(challengeBytes);
            const storedCredentialIDBytes =
                await fromB64URLSafeNoPadding(storedCredentialID);

            const credential = (await navigator.credentials.get({
                publicKey: {
                    challenge: challengeBytes,
                    allowCredentials: [
                        {
                            id: storedCredentialIDBytes,
                            type: "public-key",
                            transports: ["internal"],
                        },
                    ],
                    timeout: webAuthnTimeoutMs,
                    userVerification: "required",
                },
            })) as PublicKeyCredential | null;

            if (!credential) {
                return "failed";
            }

            const response =
                credential.response as AuthenticatorAssertionResponse;
            const clientData = parseClientDataJSON(response.clientDataJSON);
            if (!clientData) {
                return "failed";
            }

            const challengeMatches =
                normalizeB64URLNoPadding(clientData.challenge ?? "") ===
                challengeB64;
            if (!challengeMatches || clientData.type !== "webauthn.get") {
                log.error("Device lock unlock challenge verification failed");
                return "failed";
            }

            if (clientData.origin !== window.location.origin) {
                log.error("Device lock unlock origin verification failed");
                return "failed";
            }

            const credentialIDMatches =
                normalizeB64URLNoPadding(
                    await toB64URLSafeNoPadding(
                        new Uint8Array(credential.rawId),
                    ),
                ) === normalizeB64URLNoPadding(storedCredentialID);
            if (!credentialIDMatches) {
                log.error("Device lock unlock credential ID mismatch");
                return "failed";
            }

            if (!isUserVerified(response.authenticatorData)) {
                log.error("Device lock unlock missing user verification");
                return "failed";
            }

            await resetBruteForceState();
            unlockLocally();
            return "success";
        } catch (e) {
            // User cancellation and timeout surface as NotAllowedError.
            if (e instanceof DOMException && e.name === "NotAllowedError") {
                return "failed";
            }

            log.error("Failed device lock unlock attempt", e);
            return "failed";
        }
    };

/**
 * Attempt to unlock the app with the given PIN or password.
 *
 * Implements brute-force protection: after 5 failed attempts, a cooldown
 * period is enforced (exponential backoff starting at 30s). After 10 failed
 * attempts, signals that the caller should force-logout the user.
 */
export const attemptUnlock = async (input: string): Promise<UnlockResult> => {
    if (_state.snapshot.lockType === "none") {
        return "failed";
    }

    // Ensure persisted lockout state has been rehydrated before enforcing.
    await ensureBruteForceStateHydrated();

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
        await resetBruteForceState();
        unlockLocally();
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
        setSnapshot({ ..._state.snapshot, invalidAttemptCount: count });
    }

    return "failed";
};

/**
 * Lock the app and broadcast to other tabs.
 */
export const lock = () => {
    setSnapshot({ ..._state.snapshot, isLocked: true });
    hydrateBruteForceStateIfNeeded();
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
    localStorage.removeItem(lsKeyDeviceLockEnabled);
    localStorage.removeItem(lsKeyAutoLockTimeMs);

    await Promise.all([
        clearPassphraseMaterial(),
        removeKV(kvKeyInvalidAttempts),
        removeKV(kvKeyCooldownExpiresAt),
        removeKV(kvKeyWebAuthnCredentialID),
    ]);

    stopBruteForceStateHydration();
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
 * Disable app lock entirely.
 *
 * Clears all stored credentials from KV DB, resets attempts and cooldown, and
 * updates localStorage and in-memory state.
 */
export const disableAppLock = async () => {
    await Promise.all([
        clearPassphraseMaterial(),
        removeKV(kvKeyInvalidAttempts),
        removeKV(kvKeyCooldownExpiresAt),
        removeKV(kvKeyWebAuthnCredentialID),
    ]);

    localStorage.setItem(lsKeyEnabled, "false");
    localStorage.removeItem(lsKeyLockType);
    localStorage.removeItem(lsKeyDeviceLockEnabled);

    setSnapshot({
        ..._state.snapshot,
        enabled: false,
        lockType: "none",
        deviceLockEnabled: false,
        isLocked: false,
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
};
