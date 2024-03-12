import { app } from "electron";
import { CustomErrors } from "../../constants/errors";
export const isDev = !app.isPackaged;

export const promiseWithTimeout = async <T>(
    request: Promise<T>,
    timeout: number,
): Promise<T> => {
    const timeoutRef: {
        current: NodeJS.Timeout;
    } = { current: null };
    const rejectOnTimeout = new Promise<null>((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomErrors.WAIT_TIME_EXCEEDED)),
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
