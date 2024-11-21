import { wait } from "@/utils/promise";

/**
 * Retry a async operation like a HTTP request 3 (+ 1 original) times with
 * exponential backoff.
 *
 * @param op A function that performs the operation, returning the promise for
 * its completion.
 *
 * @param abortIfNeeded An optional function that is called with the
 * corresponding error whenever {@link op} rejects. It should throw the error if
 * the retries should immediately be aborted.
 *
 * @returns A promise that fulfills with to the result of a first successfully
 * fulfilled promise of the 4 (1 + 3) attempts, or rejects with the error
 * obtained either when {@link abortIfNeeded} throws, or with the error from the
 * last attempt otherwise.
 */
export const retryAsyncOperation = async <T>(
    op: () => Promise<T>,
    abortIfNeeded?: (error: unknown) => void,
): Promise<T> => {
    const waitTimeBeforeNextTry = [2000, 5000, 10000];

    while (true) {
        try {
            return await op();
        } catch (e) {
            if (abortIfNeeded) {
                abortIfNeeded(e);
            }
            const t = waitTimeBeforeNextTry.shift();
            if (!t) throw e;
            await wait(t);
        }
    }
};
