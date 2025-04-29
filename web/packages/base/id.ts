import { customAlphabet } from "nanoid";

/**
 * Remove _ and - from the default set to have better looking IDs that can also
 * be selected in the editor quickly ("-" prevents this), and which we can
 * prefix unambiguously ("_" is used for that).
 *
 * To compensate, increase length from the default of 21 to 22.
 *
 * To play around with these, use https://zelark.github.io/nano-id-cc/
 */
export const alphabet =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

const nanoid = customAlphabet(alphabet, 22);

/**
 * Generate a new random identifier with the given prefix.
 *
 * Internally this uses [nanoids](https://github.com/ai/nanoid).
 *
 * See {@link newNonSecureID} for a variant that can be used in web workers.
 */
export const newID = (prefix: string) => prefix + nanoid();
