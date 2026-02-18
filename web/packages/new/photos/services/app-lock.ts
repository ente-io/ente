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
const maxInvalidUnlockAttempts = 10;
const cooldownStartsAtAttempt = 5;
const cooldownBaseSeconds = 30;
const unlockAttemptLockName = "ente-app-lock-unlock-attempt";

/**
 * Return the cooldown duration for a failed-attempt count.
 *
 * This policy is shared by both lockout enforcement and cooldown UI.
 */
export const appLockCooldownDurationMs = (attemptCount: number): number => {
    if (attemptCount < cooldownStartsAtAttempt) return 0;
    return (
        Math.pow(2, attemptCount - cooldownStartsAtAttempt) *
        cooldownBaseSeconds *
        1000
    );
};

// -- BroadcastChannel for multi-tab sync --

const _channel =
    typeof BroadcastChannel != "undefined"
        ? new BroadcastChannel("ente-app-lock")
        : undefined;

interface AppLockConfigSyncMessage {
    type: "config-updated";
    enabled: AppLockState["enabled"];
    lockType: AppLockState["lockType"];
    deviceLockEnabled: AppLockState["deviceLockEnabled"];
    autoLockTimeMs: AppLockState["autoLockTimeMs"];
}

interface AppLockBruteForceSyncMessage {
    type: "bruteforce-updated";
    invalidAttemptCount: AppLockState["invalidAttemptCount"];
    cooldownExpiresAt: AppLockState["cooldownExpiresAt"];
}

type AppLockChannelMessage =
    | { type: "lock" }
    | { type: "unlock" }
    | AppLockConfigSyncMessage
    | AppLockBruteForceSyncMessage;

const postChannelMessage = (payload: AppLockChannelMessage) => {
    _channel?.postMessage(payload);
};

const appLockConfigFromSnapshot = (
    snapshot: AppLockState,
): Omit<AppLockConfigSyncMessage, "type"> => ({
    enabled: snapshot.enabled,
    lockType: snapshot.lockType,
    deviceLockEnabled: snapshot.deviceLockEnabled,
    autoLockTimeMs: snapshot.autoLockTimeMs,
});

const syncConfigAcrossTabs = (snapshot: AppLockState) => {
    const payload: AppLockConfigSyncMessage = {
        type: "config-updated",
        ...appLockConfigFromSnapshot(snapshot),
    };
    postChannelMessage(payload);
};

const syncBruteForceAcrossTabs = (
    invalidAttemptCount: number,
    cooldownExpiresAt: number,
) => {
    const payload: AppLockBruteForceSyncMessage = {
        type: "bruteforce-updated",
        invalidAttemptCount,
        cooldownExpiresAt,
    };
    postChannelMessage(payload);
};

const setBruteForceSnapshot = (
    invalidAttemptCount: number,
    cooldownExpiresAt: number,
    shouldBroadcast = false,
) => {
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
    if (shouldBroadcast) {
        syncBruteForceAcrossTabs(invalidAttemptCount, cooldownExpiresAt);
    }
};

const readBruteForceStateFromKV = async () => {
    const [invalidAttempts, cooldownExpiry] = await Promise.all([
        getKVN(kvKeyInvalidAttempts),
        getKVN(kvKeyCooldownExpiresAt),
    ]);

    return {
        invalidAttemptCount: Math.max(0, invalidAttempts ?? 0),
        cooldownExpiresAt: Math.max(0, cooldownExpiry ?? 0),
    };
};

const normalizeLockType = (lockType: string): AppLockState["lockType"] =>
    lockType === "pin" || lockType === "password" || lockType === "none"
        ? lockType
        : "none";

const clampNonNegativeInt = (value: number) =>
    Number.isFinite(value) ? Math.max(0, Math.floor(value)) : 0;

interface PersistedAppLockConfig {
    enabled: boolean;
    lockType: AppLockState["lockType"];
    deviceLockEnabled: boolean;
    autoLockTimeMs: number;
}

const readPersistedAppLockConfig = (): PersistedAppLockConfig => {
    const enabled = localStorage.getItem(lsKeyEnabled) === "true";
    const lockTypeRaw = localStorage.getItem(lsKeyLockType);
    const hasLegacyDeviceLockType =
        lockTypeRaw === "biometric" || lockTypeRaw === "deviceLock";
    const hasDeviceLockFlag =
        localStorage.getItem(lsKeyDeviceLockEnabled) === "true";

    if (hasLegacyDeviceLockType) {
        localStorage.setItem(lsKeyDeviceLockEnabled, "true");
        localStorage.removeItem(lsKeyLockType);
    }

    // Remove stale key from removed "hide content when switching apps" setting.
    localStorage.removeItem("appLock.hideContentOnBlur");

    return {
        enabled,
        lockType: normalizeLockType(lockTypeRaw ?? "none"),
        deviceLockEnabled: hasDeviceLockFlag || hasLegacyDeviceLockType,
        autoLockTimeMs: clampNonNegativeInt(
            Number(localStorage.getItem(lsKeyAutoLockTimeMs) ?? "0"),
        ),
    };
};

const setSnapshotFromPersistedConfig = (
    config: PersistedAppLockConfig,
    isLocked: boolean,
) => {
    setSnapshot({
        ..._state.snapshot,
        enabled: config.enabled,
        lockType: config.lockType,
        deviceLockEnabled: config.deviceLockEnabled,
        isLocked,
        autoLockTimeMs: config.autoLockTimeMs,
    });
    hydrateBruteForceStateIfNeeded();
};

let _localUnlockAttemptQueue = Promise.resolve();

const withLocalUnlockAttemptLock = async <T>(fn: () => Promise<T>) => {
    const previous = _localUnlockAttemptQueue;
    let releaseCurrent: (() => void) | undefined;

    _localUnlockAttemptQueue = new Promise<void>((resolve) => {
        releaseCurrent = resolve;
    });

    await previous;
    try {
        return await fn();
    } finally {
        releaseCurrent?.();
    }
};

const withUnlockAttemptLock = async <T>(fn: () => Promise<T>) => {
    const locks =
        typeof navigator == "undefined"
            ? undefined
            : (navigator as Navigator & { locks?: LockManager }).locks;

    if (locks && typeof locks.request == "function") {
        const result: unknown = await locks.request(
            unlockAttemptLockName,
            { mode: "exclusive" },
            fn,
        );
        return result as T;
    }

    return withLocalUnlockAttemptLock(fn);
};

if (_channel) {
    _channel.onmessage = (event: MessageEvent) => {
        const data = event.data as AppLockChannelMessage;

        switch (data.type) {
            case "lock":
                setSnapshot({ ..._state.snapshot, isLocked: true });
                hydrateBruteForceStateIfNeeded();
                break;
            case "unlock":
                setSnapshot({
                    ..._state.snapshot,
                    isLocked: false,
                    invalidAttemptCount: 0,
                    cooldownExpiresAt: 0,
                });
                stopBruteForceStateHydration();
                break;
            case "config-updated": {
                const lockType = normalizeLockType(data.lockType);
                const autoLockTimeMs = clampNonNegativeInt(data.autoLockTimeMs);

                if (!data.enabled) {
                    setSnapshot({
                        ..._state.snapshot,
                        enabled: false,
                        lockType: "none",
                        deviceLockEnabled: false,
                        autoLockTimeMs,
                        isLocked: false,
                        invalidAttemptCount: 0,
                        cooldownExpiresAt: 0,
                    });
                    stopBruteForceStateHydration();
                    break;
                }

                setSnapshot({
                    ..._state.snapshot,
                    enabled: data.enabled,
                    lockType,
                    deviceLockEnabled: data.deviceLockEnabled,
                    autoLockTimeMs,
                });
                hydrateBruteForceStateIfNeeded();
                break;
            }
            case "bruteforce-updated":
                setBruteForceSnapshot(
                    clampNonNegativeInt(data.invalidAttemptCount),
                    clampNonNegativeInt(data.cooldownExpiresAt),
                );
                break;
        }
    };
}

// -- Public API --

/**
 * Initialize app lock state from localStorage on cold start.
 *
 * Reads localStorage synchronously so the overlay can render immediately
 * without a flash of unlocked content. On desktop startup, it locks
 * pessimistically while safe-storage hydration is in flight.
 *
 * After the synchronous snapshot, asynchronously restores the brute-force
 * attempt count and cooldown expiry from KV DB so that a page refresh cannot
 * bypass the cooldown.
 */
export const initAppLock = () => {
    const config = readPersistedAppLockConfig();
    const hasSession = haveMasterKeyInSession();

    // On desktop, lock pessimistically while safe-storage hydration is in flight.
    const isLocked = config.enabled && (hasSession || !!globalThis.electron);

    setSnapshotFromPersistedConfig(config, isLocked);
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
        const { invalidAttemptCount, cooldownExpiresAt } =
            await readBruteForceStateFromKV();

        if (generation !== _bruteForceStateHydrationGeneration) {
            return;
        }

        setBruteForceSnapshot(invalidAttemptCount, cooldownExpiresAt);
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

const isArrayBuffer = (value: unknown): value is ArrayBuffer =>
    value instanceof ArrayBuffer;

const assertionResponseFromCredential = (credential: PublicKeyCredential) => {
    const response = credential.response as
        | AuthenticatorAssertionResponse
        | undefined;
    if (!response) return undefined;

    if (
        !isArrayBuffer(response.clientDataJSON) ||
        !isArrayBuffer(response.authenticatorData) ||
        !isArrayBuffer(response.signature)
    ) {
        return undefined;
    }

    if (
        response.clientDataJSON.byteLength === 0 ||
        response.authenticatorData.byteLength === 0 ||
        response.signature.byteLength === 0
    ) {
        return undefined;
    }

    return response;
};

const clearPassphraseMaterial = async () =>
    Promise.all([
        removeKV(kvKeyHash),
        removeKV(kvKeySalt),
        removeKV(kvKeyOpsLimit),
        removeKV(kvKeyMemLimit),
    ]);

const resetBruteForceState = async (shouldBroadcast = false) => {
    await Promise.all([
        setKV(kvKeyInvalidAttempts, 0),
        setKV(kvKeyCooldownExpiresAt, 0),
    ]);
    setBruteForceSnapshot(0, 0, shouldBroadcast);
};

const unlockLocally = () => {
    setSnapshot({
        ..._state.snapshot,
        isLocked: false,
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
    postChannelMessage({ type: "unlock" });
};

/**
 * Recompute and refresh whether the app should currently be locked based on
 * session availability.
 *
 * Call this after desktop safe-storage restore to prevent auto-login bypass.
 */
export const refreshAppLockStateFromSession = () => {
    const config = readPersistedAppLockConfig();
    const isLocked = config.enabled && haveMasterKeyInSession();
    setSnapshotFromPersistedConfig(config, isLocked);
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
const setupPassphraseLock = async (
    lockType: Extract<AppLockState["lockType"], "pin" | "password">,
    input: string,
) => {
    const derived = await deriveInteractiveKey(input);
    await Promise.all([
        setKV(kvKeyHash, derived.key),
        setKV(kvKeySalt, derived.salt),
        setKV(kvKeyOpsLimit, derived.opsLimit),
        setKV(kvKeyMemLimit, derived.memLimit),
        resetBruteForceState(true),
    ]);

    localStorage.setItem(lsKeyLockType, lockType);
    localStorage.setItem(lsKeyEnabled, "true");

    setSnapshot({
        ..._state.snapshot,
        enabled: true,
        lockType,
        invalidAttemptCount: 0,
        cooldownExpiresAt: 0,
    });
    stopBruteForceStateHydration();
    syncConfigAcrossTabs(_state.snapshot);
};

export const setupPin = async (pin: string) => setupPassphraseLock("pin", pin);

/**
 * Set up a password for app lock.
 *
 * Same as {@link setupPin} but sets the lock type to "password".
 */
export const setupPassword = async (password: string) =>
    setupPassphraseLock("password", password);

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

                    await resetBruteForceState(true);

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
                    syncConfigAcrossTabs(_state.snapshot);

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
            resetBruteForceState(true),
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
        syncConfigAcrossTabs(_state.snapshot);

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
 *
 * Security note: This flow uses browser-provided credential APIs and validates
 * challenge/type/origin/credential-id/user-verification locally. It is
 * designed as a local app-lock boundary, not as a replacement for server-side
 * WebAuthn authentication ceremonies.
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

            if (credential.type !== "public-key") {
                log.error("Device lock unlock credential type mismatch");
                return "failed";
            }
            if (!(credential.rawId instanceof ArrayBuffer)) {
                log.error("Device lock unlock credential rawId missing");
                return "failed";
            }
            if (credential.rawId.byteLength === 0) {
                log.error("Device lock unlock credential rawId is empty");
                return "failed";
            }

            const response = assertionResponseFromCredential(credential);
            if (!response) {
                log.error("Device lock unlock response is malformed");
                return "failed";
            }

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

    return withUnlockAttemptLock<UnlockResult>(async () => {
        // Ensure persisted lockout state has been rehydrated before enforcing.
        await ensureBruteForceStateHydrated();

        // Refresh lockout state from KV so stale tabs cannot reset counters.
        const persistedState = await readBruteForceStateFromKV();
        const invalidAttemptCount = Math.max(
            _state.snapshot.invalidAttemptCount,
            persistedState.invalidAttemptCount,
        );
        const cooldownExpiresAt = Math.max(
            _state.snapshot.cooldownExpiresAt,
            persistedState.cooldownExpiresAt,
        );
        setBruteForceSnapshot(invalidAttemptCount, cooldownExpiresAt);

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
            await resetBruteForceState(true);
            unlockLocally();
            return "success";
        }

        // Incorrect input: increment attempts.
        const count = invalidAttemptCount + 1;
        await setKV(kvKeyInvalidAttempts, count);

        if (count >= maxInvalidUnlockAttempts) {
            // Too many attempts: signal logout.
            await setKV(kvKeyCooldownExpiresAt, 0);
            setBruteForceSnapshot(count, 0, true);
            return "logout";
        }

        if (count >= cooldownStartsAtAttempt) {
            // Enforce cooldown with exponential backoff.
            const expiresAt = Date.now() + appLockCooldownDurationMs(count);
            await setKV(kvKeyCooldownExpiresAt, expiresAt);
            setBruteForceSnapshot(count, expiresAt, true);

            // The current failed attempt has triggered cooldown, so surface the
            // cooldown state immediately to callers/UI.
            return "cooldown";
        } else {
            setBruteForceSnapshot(count, 0, true);
        }

        return "failed";
    });
};

/**
 * Lock the app and broadcast to other tabs.
 */
export const lock = () => {
    setSnapshot({ ..._state.snapshot, isLocked: true });
    hydrateBruteForceStateIfNeeded();
    postChannelMessage({ type: "lock" });
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
    syncConfigAcrossTabs(_state.snapshot);
    syncBruteForceAcrossTabs(0, 0);
    postChannelMessage({ type: "unlock" });
};

/**
 * Update the auto-lock delay.
 */
export const setAutoLockTime = (ms: number) => {
    const autoLockTimeMs = clampNonNegativeInt(ms);
    localStorage.setItem(lsKeyAutoLockTimeMs, String(autoLockTimeMs));
    setSnapshot({ ..._state.snapshot, autoLockTimeMs });
    syncConfigAcrossTabs(_state.snapshot);
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
    syncConfigAcrossTabs(_state.snapshot);
    syncBruteForceAcrossTabs(0, 0);
};
