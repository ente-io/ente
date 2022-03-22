import { CustomError } from 'utils/error';

export const promiseWithTimeout = async (
    request: Promise<any>,
    timeout: number
) => {
    const rejectOnTimeout = new Promise((_, reject) => {
        setTimeout(
            () => reject(Error(CustomError.WAIT_TIME_EXCEEDED)),
            timeout
        );
    });
    await Promise.race([request, rejectOnTimeout]);
};
