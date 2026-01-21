/**
 * A parsed representation of an OTP code URI.
 */
export interface Code {
    /** A unique id for the corresponding "auth entity" in our system. */
    id: string;
    /** The type of the code. */
    type: "totp" | "hotp" | "steam";
    /** The user's account or email for which this code is used. */
    account?: string;
    /** The name of the entity that issued this code. */
    issuer: string;
    /**
     * Length of the generated OTP.
     */
    length: number;
    /**
     * The time period (in seconds) for which a single OTP generated from this
     * code remains valid.
     */
    period: number;
    /** The (HMAC) algorithm used by the OTP generator. */
    algorithm: "sha1" | "sha256" | "sha512";
    /**
     * HOTP counter.
     * Only valid for HOTP codes.
     */
    counter?: number;
    /**
     * The secret that is used to drive the OTP generator.
     * Base32 encoded.
     */
    secret: string;
    /**
     * Optional metadata containing Ente specific metadata.
     */
    codeDisplay: CodeDisplay | undefined;
    /** The original string from which this code was generated. */
    uriString: string;
}

export interface CodeDisplay {
    /** True if this code is in the Trash. */
    trashed?: boolean;
    /** True if this code has been pinned by the user. */
    pinned?: boolean;
    /** User-provided note or description for this code. */
    note?: string;
}

/**
 * Theme mode for the extension.
 */
export type ThemeMode = "light" | "dark" | "system";

/**
 * Auth codes and time offset from sync.
 */
export interface AuthCodesAndTimeOffset {
    codes: Code[];
    /** Approximate correction (milliseconds) for TOTP derivation. */
    timeOffset?: number;
}

/**
 * Extension settings stored in local storage.
 */
export interface ExtensionSettings {
    /** Enable autofill functionality. Default: true */
    autofillEnabled: boolean;
    /** Sync interval in minutes. Default: 5 */
    syncInterval: number;
    /** Custom API endpoint for self-hosted instances. */
    customApiEndpoint?: string;
    /** Theme mode. Default: "system" */
    theme: ThemeMode;
}

/**
 * Default extension settings.
 */
export const defaultSettings: ExtensionSettings = {
    autofillEnabled: true,
    syncInterval: 5,
    theme: "system",
};

/**
 * Message types for communication between extension components.
 */
export type ExtensionMessage =
    | { type: "GET_CODES" }
    | { type: "GET_CODES_FOR_DOMAIN"; domain: string }
    | { type: "SYNC_CODES" }
    | { type: "LOGIN"; token: string; keyAttributes: KeyAttributes }
    | { type: "LOGIN_SRP"; email: string; password: string }
    | { type: "OPEN_WEB_LOGIN" }
    | { type: "WEB_LOGIN_CREDENTIALS"; credentials: WebLoginCredentials }
    | { type: "LOGOUT" }
    | { type: "UNLOCK"; password: string }
    | { type: "GET_AUTH_STATE" }
    | { type: "GET_SETTINGS" }
    | { type: "SET_SETTINGS"; settings: Partial<ExtensionSettings> }
    | { type: "FILL_CODE"; code: string; tabId: number };

/**
 * Credentials captured from web login.
 */
export interface WebLoginCredentials {
    token: string;
    email: string;
    userId: number;
    masterKey: string | null;
    keyAttributes: KeyAttributes;
    password: string | null;
}

/**
 * Response types for extension messages.
 */
export type ExtensionResponse =
    | { success: true; data?: unknown }
    | { success: false; error: string };

/**
 * Authentication state.
 */
export interface AuthState {
    isLoggedIn: boolean;
    isUnlocked: boolean;
    email?: string;
}

/**
 * Key attributes for deriving the master key.
 */
export interface KeyAttributes {
    kekSalt: string;
    opsLimit: number;
    memLimit: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    publicKey: string;
    encryptedSecretKey: string;
    secretKeyDecryptionNonce: string;
}

/**
 * Encrypted box result.
 */
export interface EncryptedBox {
    encryptedData: string;
    nonce: string;
}

/**
 * Encrypted blob result.
 */
export interface EncryptedBlob {
    encryptedData: string;
    decryptionHeader: string;
}

/**
 * Authenticator entity key from remote.
 */
export interface AuthenticatorEntityKey {
    encryptedKey: string;
    header: string;
}

/**
 * Match result for domain matching.
 */
export interface DomainMatch {
    code: Code;
    confidence: number;
}

/**
 * MFA field detection result.
 */
export interface MFAFieldDetection {
    element: HTMLInputElement;
    confidence: number;
    type: "single" | "split";
    splitInputs?: HTMLInputElement[];
}
