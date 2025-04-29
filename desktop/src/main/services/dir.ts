import { shell } from "electron/common";
import { app, dialog } from "electron/main";
import path from "node:path";
import { posixPath } from "../utils/electron";

export const selectDirectory = async () => {
    const result = await dialog.showOpenDialog({
        properties: ["openDirectory"],
    });
    const dirPath = result.filePaths[0];
    return dirPath ? posixPath(dirPath) : undefined;
};

/**
 * Open the given {@link dirPath} in the system's folder viewer.
 *
 * For example, on macOS this'll open {@link dirPath} in Finder.
 */
export const openDirectory = async (dirPath: string) => {
    // We need to use `path.normalize` because `shell.openPath; does not support
    // POSIX path, it needs to be a platform specific path:
    // https://github.com/electron/electron/issues/28831#issuecomment-826370589
    const res = await shell.openPath(path.normalize(dirPath));
    // `shell.openPath` resolves with a string containing the error message
    // corresponding to the failure if a failure occurred, otherwise "".
    if (res) throw new Error(`Failed to open directory ${dirPath}: res`);
};

/**
 * Open the app's log directory in the system's folder viewer.
 *
 * @see {@link openDirectory}
 */
export const openLogDirectory = () => openDirectory(logDirectoryPath());

/**
 * Return the path where the logs for the app are saved.
 *
 * [Note: Electron app paths]
 *
 * There are three paths we need to be aware of usually.
 *
 * First is the "appData". We can obtain this with `app.getPath("appData")`.
 * This is per-user application data directory. This is usually the following:
 *
 * - Windows: `%APPDATA%`, e.g. `C:\Users\<username>\AppData\Local`
 * - Linux: `~/.config`
 * - macOS: `~/Library/Application Support`
 *
 * Now, if we suffix the app's name onto the appData directory, we get the
 * "userData" directory. This is the **primary** place applications are meant to
 * store user's data, e.g. various configuration files and saved state.
 *
 * Note that Chromium also stores the browser state, e.g. localStorage or disk
 * caches, in userData.
 *
 * https://www.electronjs.org/docs/latest/api/app
 *
 * [Note: App log path]
 *
 * Finally, there is the "logs" directory. This is not within "appData" but has
 * a slightly different OS specific path. Since our log file is named
 * "ente.log", it can be found at:
 *
 * - macOS: ~/Library/Logs/ente/ente.log (production)
 * - Linux: ~/.config/ente/logs/ente.log
 * - Windows: %USERPROFILE%\AppData\Roaming\ente\logs\ente.log
 */
const logDirectoryPath = () => app.getPath("logs");
