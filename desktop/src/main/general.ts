import { shell } from "electron"; /* TODO(MR): Why is this not in /main? */
import { app } from "electron/main";
import * as path from "node:path";

/** `true` if the app is running in development mode. */
export const isDev = !app.isPackaged;

/**
 * Open the given {@link dirPath} in the system's folder viewer.
 *
 * For example, on macOS this'll open {@link dirPath} in Finder.
 */
export const openDirectory = async (dirPath: string) => {
    const res = await shell.openPath(path.normalize(dirPath));
    // shell.openPath resolves with a string containing the error message
    // corresponding to the failure if a failure occurred, otherwise "".
    if (res) throw new Error(`Failed to open directory ${dirPath}: res`);
};

/**
 * Return the path where the logs for the app are saved.
 *
 * [Note: Electron app paths]
 *
 * By default, these paths are at the following locations:
 *
 * - macOS: `~/Library/Application Support/ente`
 * - Linux: `~/.config/ente`
 * - Windows: `%APPDATA%`, e.g. `C:\Users\<username>\AppData\Local\ente`
 * - Windows: C:\Users\<you>\AppData\Local\<Your App Name>
 *
 * https://www.electronjs.org/docs/latest/api/app
 *
 */
const logDirectoryPath = () => app.getPath("logs");

/**
 * Open the app's log directory in the system's folder viewer.
 *
 * @see {@link openDirectory}
 */
export const openLogDirectory = () => openDirectory(logDirectoryPath());
