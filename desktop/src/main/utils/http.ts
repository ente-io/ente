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
    "X-Client-Version": desktopAppVersion
});
