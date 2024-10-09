import { useCallback } from "react";
import { useAppContext } from "../types/context";

/**
 * Wrap an asynchronous operation (e.g. API calls) in an global activity
 * indicator and error handler.
 *
 * This function takes a async function, and wraps it in a function that starts
 * the global activity indicator, lets the promise resolve, and then stop the
 * activity indicator. If the promise rejects, then it shows a generic error.
 *
 * The global activity indicator and error alert triggering mechanism is
 * obtained from the app context.
 */
export const useWrapAsyncOperation = <T extends unknown[]>(
    f: (...args: T) => Promise<void>,
) => {
    const { startLoading, finishLoading, onGenericError } = useAppContext();
    return useCallback(
        async (...args: T) => {
            startLoading();
            try {
                await f(...args);
            } catch (e) {
                onGenericError(e);
            } finally {
                finishLoading();
            }
        },
        [f, startLoading, finishLoading, onGenericError],
    );
};
