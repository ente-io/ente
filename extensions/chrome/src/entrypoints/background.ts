/**
 * Background service worker for Ente Auth extension.
 *
 * Handles:
 * - Authentication state
 * - Sync with Ente servers
 * - Message passing to popup/content scripts
 * - Auto-lock functionality
 */
import { defineBackground } from "wxt/sandbox";
import type { BackgroundMessage, CheckEmailResult, ExtensionState, OTPResult, SiteMatchPreview } from "@/lib/types/messages";
import type { Code } from "@/lib/types/code";
import type { KeyAttributes, LocalUser } from "@/lib/types/auth";

export default defineBackground(() => {
  // Auto-lock timer
  let lockTimer: ReturnType<typeof setTimeout> | null = null;
  const AUTO_LOCK_ALARM = "autoLock";
  const TOKEN_CHECK_ALARM = "tokenCheck";
  const TOKEN_CHECK_INTERVAL_MINUTES = 10;
  const CONTENT_SCRIPT_ALLOWED_MESSAGES = new Set<BackgroundMessage["type"]>([
    "GET_CODES_FOR_SITE",
    "GENERATE_OTP",
    "GENERATE_OTPS",
    "USER_ACTIVITY",
  ]);
  // Master key is kept in-memory only to avoid persistence risks
  let inMemoryMasterKey: string | null = null;

  // Pending login helpers (persist to session storage to survive service worker restarts)
  const PENDING_LOGIN_KEY = "pendingLogin";

  const setPendingLogin = async (data: {
    id: number;
    email: string;
    keyAttributes: KeyAttributes;
    encryptedToken: string;
  } | null) => {
    if (data) {
      await chrome.storage.session.set({ [PENDING_LOGIN_KEY]: data });
    } else {
      await chrome.storage.session.remove(PENDING_LOGIN_KEY);
    }
  };

  const getPendingLogin = async (): Promise<{
    id: number;
    email: string;
    keyAttributes: KeyAttributes;
    encryptedToken: string;
  } | null> => {
    const result = await chrome.storage.session.get(PENDING_LOGIN_KEY);
    const pending = result[PENDING_LOGIN_KEY] || null;
    return pending;
  };

  /**
   * Initialize the extension.
   */
  const init = async () => {
    const { initCrypto } = await import("@/lib/crypto");
    await initCrypto();

    // Migrate legacy plaintext token storage to encryptedToken (if needed).
    await migrateLegacyTokenStorage();

    // Enforce auto-lock on startup to cover service worker restarts
    await enforceAutoLockOnStartup();
    await scheduleTokenCheck();
  };

  const migrateLegacyTokenStorage = async () => {
    try {
      const { clearAllData, localStorage } = await import("@/lib/storage");
      const user = await localStorage.getUser();
      const encryptedToken = await localStorage.getEncryptedToken();
      const keyAttributes = await localStorage.getKeyAttributes();

      if (!user || !user.token || encryptedToken) {
        return;
      }
      if (!keyAttributes?.publicKey) {
        console.warn(
          "Missing key attributes for legacy token migration; clearing local data",
        );
        await clearAllData();
        await setPendingLogin(null);
        inMemoryMasterKey = null;
        await chrome.alarms.clear(AUTO_LOCK_ALARM);
        await chrome.alarms.clear(TOKEN_CHECK_ALARM);
        if (lockTimer) {
          clearTimeout(lockTimer);
          lockTimer = null;
        }
        return;
      }

      // Legacy versions stored a plaintext token. Convert it to an encryptedToken
      // sealed to the user's public key so future unlocks can recover it.
      const { fromB64URLSafe, boxSeal } = await import("@/lib/crypto");
      const tokenBytes = await fromB64URLSafe(user.token);
      const sealed = await boxSeal(tokenBytes, keyAttributes.publicKey);

      await localStorage.setEncryptedToken(sealed);
      await localStorage.setUser({ id: user.id, email: user.email });
    } catch (e) {
      const { clearAllData } = await import("@/lib/storage");
      console.error("Legacy token migration failed; clearing local data", e);
      await clearAllData();
      await setPendingLogin(null);
      inMemoryMasterKey = null;
      await chrome.alarms.clear(AUTO_LOCK_ALARM);
      await chrome.alarms.clear(TOKEN_CHECK_ALARM);
      if (lockTimer) {
        clearTimeout(lockTimer);
        lockTimer = null;
      }
    }
  };

  /**
   * Get extension state.
   */
  const getState = async (): Promise<ExtensionState> => {
    const { isLoggedIn, localStorage, sessionStorage } = await import("@/lib/storage");
    const loggedIn = await isLoggedIn();
    const unlocked = (await sessionStorage.isUnlocked()) && !!inMemoryMasterKey;
    const user = await localStorage.getUser();

    return {
      isLoggedIn: loggedIn,
      isLocked: loggedIn && !unlocked,
      email: user?.email,
    };
  };

  /**
   * Reset the auto-lock timer.
   */
  const resetLockTimer = async () => {
    const { localStorage } = await import("@/lib/storage");
    const timeout = await localStorage.getAutoLockTimeout();

    if (lockTimer) {
      clearTimeout(lockTimer);
      lockTimer = null;
    }
    await chrome.alarms.clear(AUTO_LOCK_ALARM);

    if (timeout > 0) {
      const timeoutMs = timeout * 60 * 1000;
      lockTimer = setTimeout(lock, timeoutMs);
      await chrome.alarms.create(AUTO_LOCK_ALARM, { delayInMinutes: timeout });
      await localStorage.setLastActivityTime(Date.now());
    }
  };

  /**
   * Ensure we lock if last activity was older than auto-lock timeout.
   * This is called on service worker startup to avoid leaving the vault unlocked
   * after a suspend/resume cycle.
   */
  const enforceAutoLockOnStartup = async () => {
    const { localStorage, sessionStorage, clearVaultSession } = await import("@/lib/storage");
    const timeout = await localStorage.getAutoLockTimeout();
    if (timeout <= 0) {
      await chrome.alarms.clear(AUTO_LOCK_ALARM);
      return;
    }

    // If we don't have the master key in-memory, treat as locked and clear decrypted vault state
    if (!inMemoryMasterKey) {
      await clearVaultSession();
      await sessionStorage.setUnlocked(false);
    }

    const lastActivity = await localStorage.getLastActivityTime();
    const timeoutMs = timeout * 60 * 1000;
    const now = Date.now();

    if (lastActivity && now - lastActivity >= timeoutMs) {
      await lock();
      return;
    }

    const remainingMs = lastActivity
      ? timeoutMs - (now - lastActivity)
      : timeoutMs;

    if (lockTimer) {
      clearTimeout(lockTimer);
      lockTimer = null;
    }
    await chrome.alarms.clear(AUTO_LOCK_ALARM);
    lockTimer = setTimeout(lock, remainingMs);
    await chrome.alarms.create(AUTO_LOCK_ALARM, {
      delayInMinutes: remainingMs / (60 * 1000),
    });
  };

  const isVaultUnlocked = async (): Promise<boolean> => {
    const { sessionStorage } = await import("@/lib/storage");
    return (await sessionStorage.isUnlocked()) && !!inMemoryMasterKey;
  };

  /**
   * Schedule periodic token validity checks.
   */
  const scheduleTokenCheck = async () => {
    const { sessionStorage } = await import("@/lib/storage");
    const token = await sessionStorage.getAuthToken();
    await chrome.alarms.clear(TOKEN_CHECK_ALARM);
    if (token) {
      await chrome.alarms.create(TOKEN_CHECK_ALARM, {
        delayInMinutes: TOKEN_CHECK_INTERVAL_MINUTES,
        periodInMinutes: TOKEN_CHECK_INTERVAL_MINUTES,
      });
    }
  };

  /**
   * Validate the current auth token and lock/clear if invalid.
   */
  const validateToken = async () => {
    const { localStorage, sessionStorage, clearAllData } = await import("@/lib/storage");
    const { checkSessionValidity } = await import("@/lib/api/auth");
    const token = await sessionStorage.getAuthToken();
    if (!token) {
      return;
    }

    try {
      const result = await checkSessionValidity(token);
      if (!result.isValid || result.passwordChanged) {
        console.warn("Token invalid or password changed, locking and clearing data");
        inMemoryMasterKey = null;
        await clearAllData();
        await setPendingLogin(null);
        await sessionStorage.setUnlocked(false);
        await chrome.alarms.clear(AUTO_LOCK_ALARM);
        await chrome.alarms.clear(TOKEN_CHECK_ALARM);
      }
    } catch (e) {
      // Network/temporary issues should not log the user out
      console.error("Token validation failed", e);
    }
  };

  /**
   * Lock the extension.
   */
  const lock = async (): Promise<void> => {
    const { sessionStorage, localStorage, clearVaultSession } = await import("@/lib/storage");
    await clearVaultSession();
    await sessionStorage.setUnlocked(false);
    await localStorage.setLastActivityTime(Date.now());
    inMemoryMasterKey = null;
    await chrome.alarms.clear(AUTO_LOCK_ALARM);
    await chrome.alarms.clear(TOKEN_CHECK_ALARM);
    if (lockTimer) {
      clearTimeout(lockTimer);
      lockTimer = null;
    }
  };

  /**
   * Unlock the extension with password.
   */
  const unlock = async (password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage, sessionStorage } = await import("@/lib/storage");
      const { decryptMasterKey, decryptPrivateKey, boxSealOpenURLSafe } = await import("@/lib/crypto");
      const { syncCodes } = await import("@/lib/services/sync");

      const keyAttributes = await localStorage.getKeyAttributes();
      if (!keyAttributes) {
        return { success: false, error: "Not logged in" };
      }

      const encryptedToken = await localStorage.getEncryptedToken();
      if (!encryptedToken) {
        return { success: false, error: "Missing encrypted token. Please log in again." };
      }

      // Derive master key from password
      const masterKey = await decryptMasterKey(password, keyAttributes);
      const privateKey = await decryptPrivateKey(masterKey, keyAttributes);
      const token = await boxSealOpenURLSafe(encryptedToken, keyAttributes.publicKey, privateKey);

      // Keep master key in-memory only
      inMemoryMasterKey = masterKey;
      await sessionStorage.setUnlocked(true);
      await sessionStorage.setAuthToken(token);

      // Sync codes
      await syncCodes(masterKey);

      // Reset auto-lock timer
      await resetLockTimer();
      await scheduleTokenCheck();

      return { success: true };
    } catch (e) {
      console.error("Unlock failed:", e);
      return { success: false, error: "Invalid password" };
    }
  };

  /**
   * Unlock the extension with local app-lock passcode.
   *
   * This avoids asking the user for their account password on every unlock.
   * We store the master key encrypted with a key derived from the passcode
   * (Argon2id) and keep the decrypted master key in memory only.
   */
  const unlockWithPasscode = async (passcode: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage, sessionStorage } = await import("@/lib/storage");
      const { decryptBox, deriveKey, decryptPrivateKey, boxSealOpenURLSafe } = await import("@/lib/crypto");
      const { syncCodes } = await import("@/lib/services/sync");

      const enabled = await localStorage.isAppLockEnabled();
      const lockoutUntil = await localStorage.getAppLockLockoutUntil();
      const salt = await localStorage.getAppLockSalt();
      const opsLimit = await localStorage.getAppLockOpsLimit();
      const memLimit = await localStorage.getAppLockMemLimit();
      const encryptedMasterKey = await localStorage.getEncryptedMasterKey();
      const keyAttributes = await localStorage.getKeyAttributes();
      const encryptedToken = await localStorage.getEncryptedToken();

      const now = Date.now();
      if (lockoutUntil && now < lockoutUntil) {
        const seconds = Math.ceil((lockoutUntil - now) / 1000);
        return { success: false, error: `Too many attempts. Try again in ${seconds}s.` };
      }

      if (!enabled || !salt || !opsLimit || !memLimit || !encryptedMasterKey) {
        return { success: false, error: "Passcode lock is not set up. Please log in again." };
      }
      if (!keyAttributes || !encryptedToken) {
        return { success: false, error: "Not logged in" };
      }

      const appKey = await deriveKey(passcode, salt, opsLimit, memLimit);
      const masterKey = await decryptBox(encryptedMasterKey, appKey);
      const privateKey = await decryptPrivateKey(masterKey, keyAttributes);
      const token = await boxSealOpenURLSafe(encryptedToken, keyAttributes.publicKey, privateKey);

      inMemoryMasterKey = masterKey;
      await sessionStorage.setUnlocked(true);
      await sessionStorage.setAuthToken(token);

      await localStorage.resetAppLockFailures();
      await syncCodes(masterKey);
      await resetLockTimer();
      await scheduleTokenCheck();

      return { success: true };
    } catch (e) {
      try {
        const { localStorage } = await import("@/lib/storage");
        const attempts = (await localStorage.getAppLockFailedAttempts()) + 1;
        await localStorage.setAppLockFailedAttempts(attempts);

        // After 5 failures, exponential backoff up to 5 minutes.
        if (attempts >= 5) {
          const delaySeconds = Math.min(300, 15 * 2 ** (attempts - 5));
          await localStorage.setAppLockLockoutUntil(Date.now() + delaySeconds * 1000);
        }
      } catch {
        // Ignore: failing to store lockout state shouldn't break unlock flow.
      }

      console.error("Unlock with passcode failed:", e);
      return { success: false, error: "Invalid passcode" };
    }
  };

  /**
   * Enable (or change) local app-lock passcode.
   *
   * Requires the vault to be unlocked so we can encrypt the master key for
   * future passcode-based unlocks.
   */
  const setAppLockPasscode = async (passcode: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage } = await import("@/lib/storage");
      const { encryptBox, deriveKey, initCrypto, toB64 } = await import("@/lib/crypto");

      if (!(await isVaultUnlocked())) {
        return { success: false, error: "Unlock the extension first" };
      }
      const masterKey = inMemoryMasterKey;
      if (!masterKey) {
        return { success: false, error: "Unlock the extension first" };
      }

      // Enforce a minimum length to avoid trivially weak passcodes.
      if (!passcode || passcode.length < 6) {
        return { success: false, error: "Passcode must be at least 6 characters" };
      }

      await initCrypto();
      // Use moderate Argon2id parameters (offline attack resistance vs UX).
      const OPS_LIMIT = 3;
      const MEM_LIMIT = 64 * 1024 * 1024;

      // Generate a random salt and derive an encryption key from the passcode.
      const salt = new Uint8Array(16);
      crypto.getRandomValues(salt);
      const saltB64 = await toB64(salt);
      const appKey = await deriveKey(passcode, saltB64, OPS_LIMIT, MEM_LIMIT);

      const encryptedMasterKey = await encryptBox(masterKey, appKey);

      await localStorage.setEncryptedMasterKey(encryptedMasterKey);
      await localStorage.setAppLockEnabled(true);
      await localStorage.setAppLockSalt(saltB64);
      await localStorage.setAppLockOpsLimit(OPS_LIMIT);
      await localStorage.setAppLockMemLimit(MEM_LIMIT);
      await localStorage.resetAppLockFailures();

      return { success: true };
    } catch (e) {
      console.error("Set app lock passcode failed:", e);
      return { success: false, error: "Failed to set passcode" };
    }
  };

  const disableAppLock = async (): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage } = await import("@/lib/storage");
      await localStorage.removeAppLock();
      return { success: true };
    } catch (e) {
      console.error("Disable app lock failed:", e);
      return { success: false, error: "Failed to disable passcode lock" };
    }
  };

  /**
   * Check email to determine login method.
   */
  const checkEmail = async (email: string): Promise<CheckEmailResult> => {
    try {
      const { getSRPAttributes } = await import("@/lib/api/auth");
      const srpAttributes = await getSRPAttributes(email);

      if (!srpAttributes) {
        // User doesn't exist or hasn't set up SRP
        // Default to email MFA flow (will fail with proper error when OTT is sent)
        return { exists: false, isEmailMFAEnabled: true };
      }

      return {
        exists: true,
        isEmailMFAEnabled: srpAttributes.isEmailMFAEnabled,
      };
    } catch (e) {
      console.error("Check email failed:", e);
      // Default to email MFA on error
      return { exists: false, isEmailMFAEnabled: true };
    }
  };

  /**
   * Send OTT to email for login.
   */
  const loginSendOTT = async (email: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { sendOTT } = await import("@/lib/api/auth");
      await sendOTT(email);
      return { success: true };
    } catch (e) {
      console.error("Send OTT failed:", e);
      return { success: false, error: "Failed to send verification code" };
    }
  };

  /**
   * Verify OTT for login.
   */
  const loginVerifyOTT = async (email: string, ott: string): Promise<{ success: boolean; error?: string; needs2FA?: boolean }> => {
    try {
      const { verifyOTT } = await import("@/lib/api/auth");
      const response = await verifyOTT(email, ott);

      // Check if 2FA is required
      if (response.twoFactorSessionID || response.twoFactorSessionIDV2) {
        await setPendingLogin({
          id: response.id,
          email,
          keyAttributes: response.keyAttributes!,
          encryptedToken: "",
        });
        return { success: false, error: "Two-factor authentication is required. Please use the Ente Auth web app to complete login.", needs2FA: true };
      }

      // No 2FA, proceed with login
      if (!response.keyAttributes || !response.encryptedToken) {
        return { success: false, error: "Invalid verification response" };
      }

      // Store pending login for password entry
      await setPendingLogin({
        id: response.id,
        email,
        keyAttributes: response.keyAttributes,
        encryptedToken: response.encryptedToken,
      });

      return { success: true };
    } catch (e) {
      console.error("Verify OTT failed:", e);
      return { success: false, error: "Invalid verification code" };
    }
  };

  /**
   * Complete login with password.
   */
  const finishLogin = async (params: {
    id: number;
    email: string;
    password: string;
    keyAttributes: KeyAttributes;
    encryptedToken: string;
  }): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage, sessionStorage } = await import("@/lib/storage");
      const { decryptMasterKey, decryptPrivateKey, boxSealOpenURLSafe } = await import("@/lib/crypto");
      const { syncCodes } = await import("@/lib/services/sync");

      const masterKey = await decryptMasterKey(params.password, params.keyAttributes);
      const privateKey = await decryptPrivateKey(masterKey, params.keyAttributes);
      const token = await boxSealOpenURLSafe(
        params.encryptedToken,
        params.keyAttributes.publicKey,
        privateKey,
      );

      const user: LocalUser = { id: params.id, email: params.email };
      await localStorage.setUser(user);
      await localStorage.setKeyAttributes(params.keyAttributes);
      await localStorage.setEncryptedToken(params.encryptedToken);

      inMemoryMasterKey = masterKey;
      await sessionStorage.setUnlocked(true);
      await sessionStorage.setAuthToken(token);

      await syncCodes(masterKey);
      await resetLockTimer();
      await scheduleTokenCheck();

      return { success: true };
    } catch (e) {
      console.error("finishLogin failed:", e);
      return { success: false, error: "Invalid password" };
    }
  };

  const loginComplete = async (password: string): Promise<{ success: boolean; error?: string }> => {
    const pendingLogin = await getPendingLogin();

    if (!pendingLogin) {
      return { success: false, error: "No pending login. Please start again." };
    }

    const result = await finishLogin({
      id: pendingLogin.id,
      email: pendingLogin.email,
      password,
      keyAttributes: pendingLogin.keyAttributes,
      encryptedToken: pendingLogin.encryptedToken,
    });

    if (result.success) {
      await setPendingLogin(null);
    }

    return result;
  };

  /**
   * Login via SRP (password-only flow; no email OTP).
   */
  const loginSRP = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { getSRPAttributes } = await import("@/lib/api/auth");
      const { verifySRP } = await import("@/lib/services/srp");

      const srpAttributes = await getSRPAttributes(email);
      if (!srpAttributes) {
        return { success: false, error: "This account does not support password-only login. Use email verification instead." };
      }

      const response = await verifySRP(srpAttributes, password);

      if (response.twoFactorSessionID || response.twoFactorSessionIDV2) {
        return { success: false, error: "Two-factor authentication is required. Please use the Ente Auth web app to complete login." };
      }

      if (!response.keyAttributes || !response.encryptedToken) {
        return { success: false, error: "Invalid verification response" };
      }

      return finishLogin({
        id: response.id,
        email,
        password,
        keyAttributes: response.keyAttributes,
        encryptedToken: response.encryptedToken,
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Login failed";
      console.error("SRP login failed:", e);
      // Prefer the SRP verification error message if present.
      return { success: false, error: msg || "Login failed" };
    }
  };

  /**
   * Logout and clear all data.
   */
  const doLogout = async (): Promise<{ success: boolean }> => {
    try {
      const { localStorage, sessionStorage, clearAllData } = await import("@/lib/storage");
      const { logout } = await import("@/lib/api/auth");

      const token = await sessionStorage.getAuthToken();
      if (token) {
        try {
          await logout(token);
        } catch (e) {
          console.error("Server logout failed:", e);
        }
      }

      await clearAllData();
      await setPendingLogin(null);

      await chrome.alarms.clear(AUTO_LOCK_ALARM);
      if (lockTimer) {
        clearTimeout(lockTimer);
        lockTimer = null;
      }
      inMemoryMasterKey = null;

      return { success: true };
    } catch (e) {
      console.error("Logout failed:", e);
      return { success: true };
    }
  };

  /**
   * Get all codes.
   */
  const getCodes = async (): Promise<{ codes: Code[] }> => {
    if (!(await isVaultUnlocked())) {
      return { codes: [] };
    }
    const { getCachedCodes } = await import("@/lib/services/sync");
    const codes = await getCachedCodes();
    return { codes };
  };

  /**
   * Get codes matching a site URL.
   */
  const getCodesForSite = async (url: string): Promise<{ matches: SiteMatchPreview[] }> => {
    if (!(await isVaultUnlocked())) {
      return { matches: [] };
    }
    const { getCachedCodes } = await import("@/lib/services/sync");
    const { matchCodesToSite } = await import("@/lib/services/site-matcher");
    const codes = await getCachedCodes();
    const fullMatches = matchCodesToSite(codes, url);
    const matches: SiteMatchPreview[] = fullMatches.map((m) => ({
      score: m.score,
      matchType: m.matchType,
      code: {
        id: m.code.id,
        type: m.code.type,
        issuer: m.code.issuer,
        account: m.code.account,
        period: m.code.period,
        length: m.code.length,
        codeDisplay: m.code.codeDisplay,
      },
    }));
    return { matches };
  };

  /**
   * Generate OTP for a code.
   */
  const generateOTP = async (codeId: string): Promise<OTPResult> => {
    if (!(await isVaultUnlocked())) {
      throw new Error("Not unlocked");
    }
    const { getCachedCodes, getCachedTimeOffset } = await import("@/lib/services/sync");
    const { generateOTPs, getSecondsRemaining } = await import("@/lib/services/code");

    const codes = await getCachedCodes();
    const code = codes.find((c) => c.id === codeId);

    if (!code) {
      throw new Error("Code not found");
    }

    const timeOffset = await getCachedTimeOffset();
    const [otp, nextOtp] = generateOTPs(code, timeOffset);
    const validFor = getSecondsRemaining(code, timeOffset);

    return { otp, nextOtp, validFor };
  };

  /**
   * Generate OTPs for multiple codes (used to avoid N messages/sec from the popup/content scripts).
   */
  const generateOTPs = async (codeIds: string[]): Promise<{ otps: Record<string, OTPResult | null> }> => {
    const results: Record<string, OTPResult | null> = {};
    await Promise.all(
      codeIds.map(async (codeId) => {
        try {
          results[codeId] = await generateOTP(codeId);
        } catch {
          results[codeId] = null;
        }
      }),
    );
    return { otps: results };
  };

  /**
   * Trigger a sync.
   */
  const doSync = async (): Promise<{ success: boolean; error?: string }> => {
    try {
      const { sessionStorage } = await import("@/lib/storage");
      const { syncCodes } = await import("@/lib/services/sync");

      const masterKey = inMemoryMasterKey;
      if (!masterKey) {
        return { success: false, error: "Not unlocked" };
      }

      await syncCodes(masterKey);
      return { success: true };
    } catch (e) {
      console.error("Sync failed:", e);
      return { success: false, error: "Sync failed" };
    }
  };

  /**
   * Copy text to clipboard.
   */
  const copyToClipboard = async (text: string): Promise<{ success: boolean }> => {
    try {
      await navigator.clipboard.writeText(text);
      return { success: true };
    } catch (e) {
      console.error("Copy to clipboard failed:", e);
      return { success: false };
    }
  };

  /**
   * Handle messages from popup and content scripts.
   */
  chrome.runtime.onMessage.addListener((message: BackgroundMessage, sender, sendResponse) => {
    if (sender?.id !== chrome.runtime.id) {
      console.warn("Blocked message from non-extension sender", sender?.id);
      sendResponse({ success: false, error: "Unauthorized sender" });
      return false;
    }

    const senderUrl = typeof sender?.url === "string" ? sender.url : "";
    const isExtensionPage = senderUrl.startsWith(chrome.runtime.getURL(""));
    const isContentScript = !!sender?.tab;
    if (!isExtensionPage && !isContentScript) {
      console.warn("Blocked message from unknown sender context", sender);
      sendResponse({ success: false, error: "Unauthorized sender context" });
      return false;
    }
    if (isContentScript && !CONTENT_SCRIPT_ALLOWED_MESSAGES.has(message.type)) {
      console.warn(
        "Blocked unauthorized content-script action",
        message.type,
        senderUrl,
      );
      sendResponse({ success: false, error: "Unauthorized action" });
      return false;
    }

    // Reset auto-lock timer:
    // - Always on explicit USER_ACTIVITY (we only send this on real user actions).
    // - For extension pages (popup), on any message except GET_STATE.
    if (message.type === "USER_ACTIVITY") {
      void resetLockTimer();
    } else {
      if (isExtensionPage && message.type !== "GET_STATE") {
        void resetLockTimer();
      }
    }

    const handleMessage = async () => {
      switch (message.type) {
        case "GET_STATE":
          return getState();

        case "GET_CODES":
          return getCodes();

        case "GET_CODES_FOR_SITE":
          if (isContentScript) {
            if (!senderUrl) {
              return { matches: [] };
            }
            // Bind site matching to the sender tab URL instead of trusting caller input.
            return getCodesForSite(senderUrl);
          }
          return getCodesForSite(message.url);

        case "GENERATE_OTP":
          return generateOTP(message.codeId);

        case "GENERATE_OTPS":
          return generateOTPs(message.codeIds);

        case "SYNC":
          return doSync();

        case "LOCK":
          await lock();
          return { success: true };

        case "UNLOCK":
          return unlock(message.password);

        case "UNLOCK_WITH_PASSCODE":
          return unlockWithPasscode(message.passcode);

        case "SET_APP_LOCK_PASSCODE":
          return setAppLockPasscode(message.passcode);

        case "DISABLE_APP_LOCK":
          return disableAppLock();

        case "CHECK_EMAIL":
          return checkEmail(message.email);

        case "LOGIN_SEND_OTT":
          return loginSendOTT(message.email);

        case "LOGIN_VERIFY_OTT":
          return loginVerifyOTT(message.email, message.ott);

        case "LOGIN_SRP":
          return loginSRP(message.email, message.password);

        case "LOGIN_COMPLETE":
          return loginComplete(message.password);

        case "LOGOUT":
          return doLogout();

        case "USER_ACTIVITY":
          return { success: true };

        case "COPY_TO_CLIPBOARD":
          return copyToClipboard(message.text);

        default:
          return { success: false, error: "Unknown message type" };
      }
    };

    handleMessage()
      .then(sendResponse)
      .catch((e) => {
        console.error("Message handler error:", e);
        sendResponse({ success: false, error: e.message });
      });

    // Return true to indicate async response
    return true;
  });

  // Initialize on startup
  init();

  // Auto-lock via alarms for when the service worker wakes up later
  chrome.alarms.onAlarm.addListener(async (alarm) => {
    if (alarm.name === AUTO_LOCK_ALARM) {
      await lock();
    } else if (alarm.name === TOKEN_CHECK_ALARM) {
      await validateToken();
    }
  });
});
