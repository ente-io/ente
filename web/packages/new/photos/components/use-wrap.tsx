import React from "react";
import type { NewAppContextPhotos } from "../types/context";

/**
 * Return a wrap function.
 *
 * This wrap function itself takes an async function, and returns new
 * function by wrapping an async function in an error handler, showing the
 * global loading bar when the function runs.
 */
export const useWrapAsyncOperation = (
    /** See: [Note: Migrating components that need the app context]. */
    appContext: NewAppContextPhotos,
) => {
    const { startLoading, finishLoading, onGenericError } = appContext;

    const wrap = React.useCallback(
        (f: () => Promise<void>) => {
            const wrapped = async () => {
                startLoading();
                try {
                    await f();
                } catch (e) {
                    onGenericError(e);
                } finally {
                    finishLoading();
                }
            };
            return (): void => void wrapped();
        },
        [onGenericError, startLoading, finishLoading],
    );

    return wrap;
};
