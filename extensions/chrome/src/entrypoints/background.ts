/**
 * Background service worker for Ente Auth extension.
 *
 * Handles:
 * - Authentication state
 * - Sync with Ente servers
 * - Message passing to popup/content scripts
 * - Auto-lock functionality
 */
import type { BackgroundMessage, CheckEmailResult, ExtensionState, OTPResult, SiteMatch } from "@/lib/types/messages";
import type { Code } from "@/lib/types/code";
import type { KeyAttributes, LocalUser } from "@/lib/types/auth";

export default defineBackground(() => {
  // Auto-lock timer
  let lockTimer: ReturnType<typeof setTimeout> | null = null;
  const AUTO_LOCK_ALARM = "autoLock";

  // Pending login helpers (persist to session storage to survive service worker restarts)
  const PENDING_LOGIN_KEY = "pendingLogin";

  const setPendingLogin = async (data: {
    id: number;
    email: string;
    keyAttributes: KeyAttributes;
    encryptedToken: string;
  } | null) => {
    if (data) {
      console.log("setPendingLogin: storing pending login for", data.email);
      await chrome.storage.session.set({ [PENDING_LOGIN_KEY]: data });
    } else {
      console.log("setPendingLogin: clearing pending login");
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
    console.log("getPendingLogin:", pending ? `found for ${pending.email}` : "not found");
    return pending;
  };

  /**
   * Initialize the extension.
   */
  const init = async () => {
    const { initCrypto } = await import("@/lib/crypto");
    await initCrypto();
    console.log("Ente Auth extension initialized");

    // Enforce auto-lock on startup to cover service worker restarts
    await enforceAutoLockOnStartup();
  };

  /**
   * Get extension state.
   */
  const getState = async (): Promise<ExtensionState> => {
    const { isLoggedIn, localStorage, sessionStorage } = await import("@/lib/storage");
    const loggedIn = await isLoggedIn();
    const unlocked = await sessionStorage.isUnlocked();
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
    const { localStorage } = await import("@/lib/storage");
    const timeout = await localStorage.getAutoLockTimeout();
    if (timeout <= 0) {
      await chrome.alarms.clear(AUTO_LOCK_ALARM);
      return;
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

  /**
   * Lock the extension.
   */
  const lock = async (): Promise<void> => {
    const { sessionStorage, localStorage } = await import("@/lib/storage");
    await sessionStorage.clear();
    await localStorage.setLastActivityTime(Date.now());
    await chrome.alarms.clear(AUTO_LOCK_ALARM);
    if (lockTimer) {
      clearTimeout(lockTimer);
      lockTimer = null;
    }
    console.log("Extension locked");
  };

  /**
   * Unlock the extension with password.
   */
  const unlock = async (password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { localStorage, sessionStorage } = await import("@/lib/storage");
      const { decryptMasterKey } = await import("@/lib/crypto");
      const { syncCodes } = await import("@/lib/services/sync");

      const keyAttributes = await localStorage.getKeyAttributes();
      if (!keyAttributes) {
        return { success: false, error: "Not logged in" };
      }

      // Derive master key from password
      const masterKey = await decryptMasterKey(password, keyAttributes);

      // Store master key in session
      await sessionStorage.setMasterKey(masterKey);
      await sessionStorage.setUnlocked(true);

      // Sync codes
      await syncCodes(masterKey);

      // Reset auto-lock timer
      await resetLockTimer();

      return { success: true };
    } catch (e) {
      console.error("Unlock failed:", e);
      return { success: false, error: "Invalid password" };
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
  const loginComplete = async (password: string): Promise<{ success: boolean; error?: string }> => {
    // Get pending login first
    const pendingLogin = await getPendingLogin();
    console.log("loginComplete: pendingLogin =", pendingLogin ? "exists" : "null");

    if (!pendingLogin) {
      return { success: false, error: "No pending login. Please start again." };
    }

    const { id, email, keyAttributes, encryptedToken } = pendingLogin;

    // Try to decrypt - if it fails, pending login should remain for retry
    try {
      const { localStorage, sessionStorage } = await import("@/lib/storage");
      const { decryptMasterKey, decryptPrivateKey, boxSealOpenURLSafe } = await import("@/lib/crypto");
      const { syncCodes } = await import("@/lib/services/sync");

      // Decrypt master key - this will throw if password is wrong
      const masterKey = await decryptMasterKey(password, keyAttributes);
      console.log("loginComplete: masterKey decrypted successfully");

      // Decrypt private key
      const privateKey = await decryptPrivateKey(masterKey, keyAttributes);
      console.log("loginComplete: privateKey decrypted successfully");

      // Decrypt auth token (uses URL-safe base64 encoding)
      const token = await boxSealOpenURLSafe(encryptedToken, keyAttributes.publicKey, privateKey);
      console.log("loginComplete: token decrypted successfully");

      // Store user data
      const user: LocalUser = { id, email, token };
      await localStorage.setUser(user);
      await localStorage.setKeyAttributes(keyAttributes);

      // Store master key in session
      await sessionStorage.setMasterKey(masterKey);
      await sessionStorage.setUnlocked(true);

      // Only clear pending login on SUCCESS
      await setPendingLogin(null);
      console.log("loginComplete: login successful, cleared pendingLogin");

      // Sync codes
      await syncCodes(masterKey);

      // Reset auto-lock timer
      await resetLockTimer();

      return { success: true };
    } catch (e) {
      // Password decryption failed - DO NOT clear pending login
      // so user can retry with correct password
      console.error("Login complete failed (pendingLogin preserved for retry):", e);
      return { success: false, error: "Invalid password" };
    }
  };

  /**
   * Logout and clear all data.
   */
  const doLogout = async (): Promise<{ success: boolean }> => {
    try {
      const { localStorage, clearAllData } = await import("@/lib/storage");
      const { logout } = await import("@/lib/api/auth");

      const user = await localStorage.getUser();
      if (user?.token) {
        try {
          await logout(user.token);
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
    const { getCachedCodes } = await import("@/lib/services/sync");
    const codes = await getCachedCodes();
    return { codes };
  };

  /**
   * Get codes matching a site URL.
   */
  const getCodesForSite = async (url: string): Promise<{ matches: SiteMatch[] }> => {
    const { getCachedCodes } = await import("@/lib/services/sync");
    const { matchCodesToSite } = await import("@/lib/services/site-matcher");
    const codes = await getCachedCodes();
    const matches = matchCodesToSite(codes, url);
    return { matches };
  };

  /**
   * Generate OTP for a code.
   */
  const generateOTP = async (codeId: string): Promise<OTPResult> => {
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
   * Trigger a sync.
   */
  const doSync = async (): Promise<{ success: boolean; error?: string }> => {
    try {
      const { sessionStorage } = await import("@/lib/storage");
      const { syncCodes } = await import("@/lib/services/sync");

      const masterKey = await sessionStorage.getMasterKey();
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
  chrome.runtime.onMessage.addListener((message: BackgroundMessage, _sender, sendResponse) => {
    // Reset auto-lock timer on any activity
    if (message.type !== "GET_STATE") {
      resetLockTimer();
    }

    const handleMessage = async () => {
      switch (message.type) {
        case "GET_STATE":
          return getState();

        case "GET_CODES":
          return getCodes();

        case "GET_CODES_FOR_SITE":
          return getCodesForSite(message.url);

        case "GENERATE_OTP":
          return generateOTP(message.codeId);

        case "SYNC":
          return doSync();

        case "LOCK":
          await lock();
          return { success: true };

        case "UNLOCK":
          return unlock(message.password);

        case "CHECK_EMAIL":
          return checkEmail(message.email);

        case "LOGIN_SEND_OTT":
          return loginSendOTT(message.email);

        case "LOGIN_VERIFY_OTT":
          return loginVerifyOTT(message.email, message.ott);

        case "LOGIN_COMPLETE":
          return loginComplete(message.password);

        case "LOGOUT":
          return doLogout();

        case "USER_ACTIVITY":
          await resetLockTimer();
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

  console.log("Ente Auth background script loaded");

  // Auto-lock via alarms for when the service worker wakes up later
  chrome.alarms.onAlarm.addListener(async (alarm) => {
    if (alarm.name === AUTO_LOCK_ALARM) {
      await lock();
    }
  });
});
