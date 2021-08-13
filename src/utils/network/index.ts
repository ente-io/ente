import { sleep } from 'utils/common';

const retrySleepTimeInMilliSeconds = [2000, 5000, 10000];

export async function retryAsyncFunction(
    func: () => Promise<any>,
    retryCount: number = 3
) {
    try {
        const resp = await func();
        return resp;
    } catch (e) {
        if (retryCount > 0) {
            await sleep(retrySleepTimeInMilliSeconds[3 - retryCount]);
            await retryAsyncFunction(func, retryCount - 1);
        } else {
            throw e;
        }
    }
}
