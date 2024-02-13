import { CustomError } from '../error';

export const promiseWithTimeout = async <T>(
    request: Promise<T>,
    timeout: number
): Promise<T> => {
    const timeoutRef = { current: null };
    const rejectOnTimeout = new Promise<null>((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            timeout
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
