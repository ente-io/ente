import chokidar from "chokidar";
import { BrowserWindow } from "electron";
import path from "path";
import log from "../main/log";
import { getWatchMappings } from "../services/watch";
import { getElectronFile } from "./fs";

/**
 * Convert a file system {@link filePath} that uses the local system specific
 * path separators into a path that uses POSIX file separators.
 */
const normalizeToPOSIX = (filePath: string) =>
    filePath.split(path.sep).join(path.posix.sep);

export function initWatcher(mainWindow: BrowserWindow) {
    const mappings = getWatchMappings();
    const folderPaths = mappings.map((mapping) => {
        return mapping.folderPath;
    });

    const watcher = chokidar.watch(folderPaths, {
        awaitWriteFinish: true,
    });
    watcher
        .on("add", async (path) => {
            mainWindow.webContents.send(
                "watch-add",
                await getElectronFile(normalizeToPOSIX(path)),
            );
        })
        .on("unlink", (path) => {
            mainWindow.webContents.send("watch-unlink", normalizeToPOSIX(path));
        })
        .on("unlinkDir", (path) => {
            mainWindow.webContents.send(
                "watch-unlink-dir",
                normalizeToPOSIX(path),
            );
        })
        .on("error", (error) => {
            log.error("Error while watching files", error);
        });

    return watcher;
}
