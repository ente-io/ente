import React from "react";
import type { NewAppContextPhotos } from "../types/context";

/**
 * Return a wrap function.
 *
 * This returned wrap function itself takes an async function, and will return a
 * new function that wraps the provided async function (a) in an error handler,
 * and (b) shows the global loading bar when the function runs.
 *
 * This legend of the three functions that are involved might help:
 *
 * - useWrap: () => wrap
 * - wrap: (f) => void
 * - f: async () => Promise<void>
 */
export const useWrapLoadError = (
    /** See: [Note: Migrating components that need the app context]. */
    { startLoading, finishLoading, onGenericError }: NewAppContextPhotos,
) =>
    React.useCallback(
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

/**
 * A variant of {@link useWrapLoadError} that does not handle the error, only
 * does the loading indicator. It also returns the async function directly
 * instead of voiding the await.
 */
export const useWrapLoadAsync = (
    /** See: [Note: Migrating components that need the app context]. */
    { startLoading, finishLoading }: NewAppContextPhotos,
) =>
    React.useCallback(
        (f: () => Promise<void>) => {
            const wrapped = async () => {
                startLoading();
                try {
                    await f();
                } finally {
                    finishLoading();
                }
            };
            return wrapped;
        },
        [startLoading, finishLoading],
    );
