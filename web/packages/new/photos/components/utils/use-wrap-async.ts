import { useBaseContext } from "ente-base/context";
import { useCallback } from "react";
import { usePhotosAppContext } from "../../types/context";

/**
 * Wrap a function returning a promise in a loading bar and error handler.
 *
 * This function wraps asynchronous operations (e.g. API calls) in an global
 * activity indicator and error handler. The global activity indicator and error
 * alert triggering mechanism is obtained from the app context.
 *
 * Specifically, this function takes an async function. It starts the global
 * activity indicator (using {@link showLoadingBar}), performs the operation,
 * and stops the activity indicator on completion (using
 * {@link hideLoadingBar}).
 *
 * If the operation throws, it shows a generic error (using
 * {@link onGenericError}).
 */
export const useWrapAsyncOperation = <T extends unknown[]>(
    f: (...args: T) => Promise<void>,
) => {
    const { onGenericError } = useBaseContext();
    const { showLoadingBar, hideLoadingBar } = usePhotosAppContext();
    return useCallback(
        async (...args: T) => {
            showLoadingBar();
            try {
                await f(...args);
            } catch (e) {
                onGenericError(e);
            } finally {
                hideLoadingBar();
            }
        },
        [f, showLoadingBar, hideLoadingBar, onGenericError],
    );
};
