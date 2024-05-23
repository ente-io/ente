/**
 * @file grab bag of utility functions.
 *
 * These are verbatim copies of functions from web code since there isn't
 * currently a common package that both of them share.
 */

/**
 * Throw an exception if the given value is `null` or `undefined`.
 */
export const ensure = <T>(v: T | null | undefined): T => {
    if (v === null) throw new Error("Required value was null");
    if (v === undefined) throw new Error("Required value was not found");
    return v;
};

/**
 * Wait for {@link ms} milliseconds
 *
 * This function is a promisified `setTimeout`. It returns a promise that
 * resolves after {@link ms} milliseconds.
 */
export const wait = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));
