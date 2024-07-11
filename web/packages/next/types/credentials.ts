import { nullToUndefined } from "@/utils/transform";
import { z } from "zod";

// TODO: Provide types
export const KeyAttributes = z.object({}).passthrough();

/**
 * The result of a successful two factor verification (totp or passkey).
 */
export const TwoFactorAuthorizationResponse = z.object({
    id: z.number(),
    /** TODO: keyAttributes is guaranteed to be returned by museum, update the
     * types to reflect that. */
    keyAttributes: KeyAttributes.nullish().transform(nullToUndefined),
    /** TODO: encryptedToken is guaranteed to be returned by museum, update the
     * types to reflect that. */
    encryptedToken: z.string().nullish().transform(nullToUndefined),
});

export type TwoFactorAuthorizationResponse = z.infer<
    typeof TwoFactorAuthorizationResponse
>;
