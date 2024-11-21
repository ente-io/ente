/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-inferrable-types */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { wait } from "@/utils/promise";

const retrySleepTimeInMilliSeconds = [2000, 5000, 10000];

/**
 * Retry a HTTP request 3 (+ 1 original) times with exponential backoff.
 *
 * @param func A function that perform the operation, returning the promise for
 * its completion.
 *
 * @param checkForBreakingError A function that is passed the error with which
 * {@link func} rejects. It should throw the error if the retries should
 * immediately be aborted.
 *
 * @returns A promise that fulfills with to the result of a successfully
 * fulfilled promise of the 4 (1 + 3) attempts, or rejects with the error of
 * either when {@link checkForBreakingError} throws, or with the error from the
 * last attempt otherwise.
 */
export async function retryHTTPCall(
    func: () => Promise<any>,
    checkForBreakingError?: (error: unknown) => void,
): Promise<any> {
    const retrier = async (
        func: () => Promise<any>,
        attemptNumber: number = 0,
    ) => {
        try {
            const resp = await func();
            return resp;
        } catch (e) {
            if (checkForBreakingError) {
                checkForBreakingError(e);
            }
            if (attemptNumber < retrySleepTimeInMilliSeconds.length) {
                await wait(retrySleepTimeInMilliSeconds[attemptNumber]!);
                return await retrier(func, attemptNumber + 1);
            } else {
                throw e;
            }
        }
    };
    return await retrier(func);
}
