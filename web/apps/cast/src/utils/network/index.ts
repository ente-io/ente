import { sleep } from "@ente/shared/sleep";

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
