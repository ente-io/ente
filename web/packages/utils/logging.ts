/**
 * Log an error
 *
 * The {@link message} property describes what went wrong. Generally (but not
 * always) in such situations we also have an "error" object that has specific
 * details about the issue - that gets passed as the second parameter.
 *
 * Note that the "error" {@link e} is not typed. This is because in JavaScript
 * any arbitrary value can be thrown. So this function allows us to pass it an
 * arbitrary value as the error, and will internally figure out how best to deal
 * with it.
 *
 * Where and how this error gets logged is dependent on where this code is
 * running. The default implementation logs a string to the console, but in
 * practice the layers above us will use the hooks provided in this file to
 * route and show this error elsewhere.
 *
 * TODO (MR): Currently this is a placeholder function to funnel error logs
 * through. This needs to do what the existing logError in @ente/shared does,
 * but it cannot have a direct Electron/Sentry dependency here. For now, we just
 * log on the console.
 */
export const logError = (message: string, e?: unknown) => {
    if (e === undefined || e === null) {
        console.error(message);
        return;
    }

    let es: string;
    if (e instanceof Error) {
        // In practice, we expect ourselves to be called with Error objects, so
        // this is the happy path so to say.
        es = `${e.name}: ${e.message}\n${e.stack}`;
    } else {
        // For the rest rare cases, use the default string serialization of e.
        es = String(e);
    }
    console.error(`${message}: ${es}`);
};
