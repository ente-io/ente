export const clientPackageName = "io.ente.photos.desktop";

/**
 * Partial implementation of {@link publicRequestHeaders} from the web source.
 * It does not contain the "X-Client-Version" because app.getVersion() is not
 * accessible to Electron utility processes.
 */
export const publicRequestHeaders = () => ({
    "X-Client-Package": clientPackageName,
    // "X-Client-Version": desktopAppVersion
});
