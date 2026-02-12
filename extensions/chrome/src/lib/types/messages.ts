import type { Code, CodeDisplay } from "./code";

/**
 * Messages sent from popup/content scripts to background.
 */
export type BackgroundMessage =
  | { type: "GET_STATE" }
  | { type: "GET_CODES" }
  | { type: "GET_CODES_FOR_SITE"; url: string }
  | { type: "GENERATE_OTP"; codeId: string }
  | { type: "GENERATE_OTPS"; codeIds: string[] }
  | { type: "SYNC" }
  | { type: "LOCK" }
  | { type: "UNLOCK"; password: string }
  | { type: "UNLOCK_WITH_PASSCODE"; passcode: string }
  | { type: "SET_APP_LOCK_PASSCODE"; passcode: string }
  | { type: "DISABLE_APP_LOCK" }
  | { type: "CHECK_EMAIL"; email: string }
  | { type: "LOGIN_SEND_OTT"; email: string }
  | { type: "LOGIN_VERIFY_OTT"; email: string; ott: string }
  | { type: "LOGIN_SRP"; email: string; password: string }
  | { type: "LOGIN_COMPLETE"; password: string }
  | { type: "LOGOUT" }
  | { type: "USER_ACTIVITY" }
  | { type: "COPY_TO_CLIPBOARD"; text: string };

/**
 * Result of checking email for login method.
 */
export interface CheckEmailResult {
  exists: boolean;
  isEmailMFAEnabled: boolean;
}

/**
 * State of the extension.
 */
export interface ExtensionState {
  isLoggedIn: boolean;
  isLocked: boolean;
  email?: string;
}

/**
 * Site match result with score.
 */
export interface SiteMatch {
  code: Code;
  score: number;
  matchType: "exact" | "domain" | "alias";
}

/**
 * A restricted code shape safe to send to content scripts.
 * (No OTP secret or OTPAuth URI string.)
 */
export interface CodePreview {
  id: string;
  type: Code["type"];
  account?: string;
  issuer: string;
  length: number;
  period: number;
  codeDisplay: CodeDisplay | undefined;
}

export interface SiteMatchPreview {
  code: CodePreview;
  score: number;
  matchType: SiteMatch["matchType"];
}

/**
 * Generated OTP result.
 */
export interface OTPResult {
  otp: string;
  nextOtp: string;
  validFor: number; // seconds remaining
}

/**
 * Response types for background messages.
 */
export type BackgroundResponse<T extends BackgroundMessage["type"]> =
  T extends "GET_STATE"
    ? ExtensionState
    : T extends "GET_CODES"
      ? { codes: Code[] }
    : T extends "GET_CODES_FOR_SITE"
      ? { matches: SiteMatchPreview[] }
    : T extends "GENERATE_OTP"
      ? OTPResult
    : T extends "GENERATE_OTPS"
      ? { otps: Record<string, OTPResult | null> }
    : T extends "CHECK_EMAIL"
      ? CheckEmailResult
    : { success: boolean; error?: string };

/**
 * Send a message to the background script and get typed response.
 */
export async function sendMessage<T extends BackgroundMessage["type"]>(
  message: BackgroundMessage & { type: T },
): Promise<BackgroundResponse<T>> {
  return chrome.runtime.sendMessage(message);
}
