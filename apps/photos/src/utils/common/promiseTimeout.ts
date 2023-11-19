import { CustomError } from '@ente/shared/error';

export const promiseWithTimeout = async (
    request: Promise<any>,
    timeout: number
) => {
    const timeoutRef = { current: null };
    const rejectOnTimeout = new Promise((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            timeout
        );
    });
    return await Promise.race([
        (async () => {
            const resp = await request;
            clearTimeout(timeoutRef.current);
            return resp;
        })(),
        rejectOnTimeout,
    ]);
};
