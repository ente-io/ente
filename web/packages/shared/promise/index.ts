import { sleep } from "@ente/shared/sleep";
import { CustomError } from "../error";

const waitTimeBeforeNextAttemptInMilliSeconds = [2000, 5000, 10000];

export async function retryAsyncFunction<T>(
    request: (abort?: () => void) => Promise<T>,
    waitTimeBeforeNextTry?: number[],
): Promise<T> {
    if (!waitTimeBeforeNextTry) {
        waitTimeBeforeNextTry = waitTimeBeforeNextAttemptInMilliSeconds;
    }

    for (
        let attemptNumber = 0;
        attemptNumber <= waitTimeBeforeNextTry.length;
        attemptNumber++
    ) {
        try {
            const resp = await request();
            return resp;
        } catch (e) {
            if (attemptNumber === waitTimeBeforeNextTry.length) {
                throw e;
            }
            await sleep(waitTimeBeforeNextTry[attemptNumber]);
        }
    }
}

export const promiseWithTimeout = async <T>(
    request: Promise<T>,
    timeout: number,
): Promise<T> => {
    const timeoutRef = { current: null };
    const rejectOnTimeout = new Promise<null>((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            timeout,
        );
    });
    const requestWithTimeOutCancellation = async () => {
        const resp = await request;
        clearTimeout(timeoutRef.current);
        return resp;
    };
    return await Promise.race([
        requestWithTimeOutCancellation(),
        rejectOnTimeout,
    ]);
};
