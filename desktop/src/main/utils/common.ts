/**
 * @file grab bag of utility functions.
 *
 * These are verbatim copies of functions from web code since there isn't
 * currently a common package that both of them share.
 */

/**
 * Wait for {@link ms} milliseconds
 *
 * This function is a promisified `setTimeout`. It returns a promise that
 * resolves after {@link ms} milliseconds.
 *
 * Duplicated from `web/packages/utils/promise.ts`.
 */
export const wait = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));
