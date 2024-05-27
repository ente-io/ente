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
 *
 * Note that this does not abort {@link promise} itself - it will still get
 * resolved to completion, just its result will be ignored if it gets resolved
 * after we've already timed out.
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
