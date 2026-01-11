import { z } from "zod";

/**
 * A parsed representation of an OTP code URI.
 * Ported from web/apps/auth/src/services/code.ts
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
   * Called "digits" for TOTP/HOTP, but steam codes use letters.
   */
  length: number;
  /**
   * The time period (in seconds) for which a single OTP remains valid.
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
   * Optional metadata containing Ente specific metadata for this code.
   */
  codeDisplay: CodeDisplay | undefined;
  /** The original string from which this code was generated. */
  uriString: string;
}

export interface CodeDisplay {
  /**
   * True if this code is in the Trash.
   */
  trashed?: boolean;
  /**
   * True if this code has been pinned by the user.
   */
  pinned?: boolean;
  /**
   * User-provided note or description for this code.
   */
  note?: string;
}

export const CodeDisplaySchema = z.object({
  trashed: z
    .boolean()
    .nullish()
    .transform((v) => v ?? undefined),
  pinned: z
    .boolean()
    .nullish()
    .transform((v) => v ?? undefined),
  note: z
    .string()
    .nullish()
    .transform((v) => v ?? undefined),
});
