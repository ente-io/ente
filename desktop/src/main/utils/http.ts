export const clientPackageName = "io.ente.photos.desktop";

/**
 * Reimplementation of {@link publicRequestHeaders} from the web source.
 *
 * @param desktopAppVersion The desktop app's version. This will get passed on
 * as the "X-Client-Version" header.
 *
 * We cannot directly use `app.getVersion()` to obtain this value since the
 * {@link app} module is not accessible to Electron utility processes which also
 * calls this function.
 */
export const publicRequestHeaders = (desktopAppVersion: string) => ({
    "X-Client-Package": clientPackageName,
    "X-Client-Version": desktopAppVersion,
});

/**
 * Reimplementation of {@link authenticatedRequestHeaders} from the web source.
 *
 * This builds on top of {@link publicRequestHeaders} and takes the same
 * parameters, and additionally also requires the {@link authToken} that will be
 * passed as the "X-Auth-Token" header.
 */
export const authenticatedRequestHeaders = (
    desktopAppVersion: string,
    authToken: string,
) => ({
    ...publicRequestHeaders(desktopAppVersion),
    "X-Auth-Token": authToken,
});
