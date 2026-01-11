/**
 * Authentication API endpoints.
 */
import { z } from "zod";
import {
  KeyAttributesSchema,
  VerificationResponseSchema,
  type KeyAttributes,
  type VerificationResponse,
} from "../types/auth";
import { apiRequest, apiRequestNoAuth } from "./client";

/**
 * SRP Attributes for a user.
 *
 * These are fetched before login to determine if email MFA is enabled
 * or if we should use SRP-based verification.
 */
export interface SRPAttributes {
  srpUserID: string;
  srpSalt: string;
  memLimit: number;
  opsLimit: number;
  kekSalt: string;
  isEmailMFAEnabled: boolean;
}

const SRPAttributesSchema = z.object({
  srpUserID: z.string(),
  srpSalt: z.string(),
  memLimit: z.number(),
  opsLimit: z.number(),
  kekSalt: z.string(),
  isEmailMFAEnabled: z.boolean(),
});

/**
 * Get SRP attributes for a user by email.
 *
 * Returns undefined if user doesn't exist or hasn't completed SRP setup.
 */
export const getSRPAttributes = async (
  email: string,
): Promise<SRPAttributes | undefined> => {
  try {
    const response = await apiRequestNoAuth<unknown>(
      `/users/srp/attributes?email=${encodeURIComponent(email)}`,
      { method: "GET" },
    );
    const parsed = z.object({ attributes: SRPAttributesSchema }).parse(response);
    return parsed.attributes;
  } catch (error) {
    // 404 means user doesn't exist or hasn't set up SRP
    if (error instanceof Error && error.message.includes("404")) {
      return undefined;
    }
    throw error;
  }
};

/**
 * Request OTT (One-Time Token) to be sent to email.
 */
export const sendOTT = async (email: string): Promise<void> => {
  await apiRequest("/users/ott", {
    method: "POST",
    body: JSON.stringify({
      email,
      purpose: "login",
    }),
  });
};

/**
 * OTT verification response schema.
 */
const OTTVerificationResponseSchema = z.object({
  id: z.number(),
  keyAttributes: KeyAttributesSchema.optional(),
  encryptedToken: z.string().optional(),
  token: z.string().optional(),
  twoFactorSessionID: z.string().optional(),
  passkeySessionID: z.string().optional(),
  twoFactorSessionIDV2: z.string().optional(),
});

/**
 * Verify OTT and get authentication response.
 */
export const verifyOTT = async (
  email: string,
  ott: string,
): Promise<VerificationResponse> => {
  const response = await apiRequest<unknown>("/users/verify-email", {
    method: "POST",
    body: JSON.stringify({
      email,
      ott,
    }),
  });
  return VerificationResponseSchema.parse(response);
};

/**
 * Response from two-factor verification.
 */
export interface TwoFactorVerificationResponse {
  id: number;
  keyAttributes: KeyAttributes;
  encryptedToken: string;
}

const TwoFactorVerificationResponseSchema = z.object({
  id: z.number(),
  keyAttributes: KeyAttributesSchema,
  encryptedToken: z.string(),
});

/**
 * Verify TOTP two-factor code.
 */
export const verifyTwoFactor = async (
  sessionID: string,
  code: string,
): Promise<TwoFactorVerificationResponse> => {
  const response = await apiRequest<unknown>("/users/two-factor/verify", {
    method: "POST",
    body: JSON.stringify({
      sessionID,
      code,
    }),
  });
  return TwoFactorVerificationResponseSchema.parse(response);
};

/**
 * Check session validity.
 */
export interface SessionValidityResponse {
  isValid: boolean;
  passwordChanged?: boolean;
}

export const checkSessionValidity = async (
  token: string,
): Promise<SessionValidityResponse> => {
  try {
    const response = await apiRequest<{ passwordChanged?: boolean }>(
      "/users/session-validity/v2",
      { method: "GET" },
      token,
    );
    return {
      isValid: true,
      passwordChanged: response.passwordChanged,
    };
  } catch (error) {
    if (error instanceof Error && error.message.includes("401")) {
      return { isValid: false };
    }
    throw error;
  }
};

/**
 * Logout (invalidate token).
 */
export const logout = async (token: string): Promise<void> => {
  await apiRequest(
    "/users/logout",
    {
      method: "POST",
    },
    token,
  );
};
