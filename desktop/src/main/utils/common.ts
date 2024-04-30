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

/**
 * Await the given {@link promise} for {@link timeoutMS} milliseconds. If it
 * does not resolve within {@link timeoutMS}, then reject with a timeout error.
 */
export const withTimeout = async <T>(promise: Promise<T>, ms: number) => {
    let timeoutId: ReturnType<typeof setTimeout>;
    const rejectOnTimeout = new Promise<T>((_, reject) => {
        timeoutId = setTimeout(
            () => reject(new Error("Operation timed out")),
            ms,
        );
    });
    const promiseAndCancelTimeout = async () => {
        const result = await promise;
        clearTimeout(timeoutId);
        return result;
    };
    return Promise.race([promiseAndCancelTimeout(), rejectOnTimeout]);
};
