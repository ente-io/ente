import { shell } from "electron/common";
import { app, dialog } from "electron/main";
import path from "node:path";
import { posixPath } from "../utils/path";

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
    const res = await shell.openPath(path.normalize(dirPath));
    // shell.openPath resolves with a string containing the error message
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
