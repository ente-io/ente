import { customAlphabet } from "nanoid/non-secure";
import { alphabet } from "./id";

const nanoid = customAlphabet(alphabet, 22);

/**
 * This is a variant of the regular {@link newID} that can be used in web
 * workers.
 *
 * Web workers don't have access to a secure random generator, so we need to use
 * the non-secure variant.
 * https://github.com/ai/nanoid?tab=readme-ov-file#web-workers
 *
 * For many of our use cases, where we're not using these IDs for cryptographic
 * operations, this is okay. We also have an increased alphabet length.
 */
export const newNonSecureID = (prefix: string) => prefix + nanoid();
