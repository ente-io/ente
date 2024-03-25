import chokidar from "chokidar";
import { BrowserWindow, dialog, ipcMain, Tray } from "electron";
import path from "path";
import { attachIPCHandlers } from "../main/ipc";
import {
    computeImageEmbedding,
    computeTextEmbedding,
} from "../services/clipService";
import { deleteTempFile } from "../services/ffmpeg";
import { getDirFilePaths } from "../services/fs";
import {
    convertToJPEG,
    generateImageThumbnail,
} from "../services/imageProcessor";
import { generateTempFilePath } from "./temp";

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow,
    watcher: chokidar.FSWatcher,
): void {
    attachIPCHandlers();

    ipcMain.handle("select-dir", async () => {
        const result = await dialog.showOpenDialog({
            properties: ["openDirectory"],
        });
        if (result.filePaths && result.filePaths.length > 0) {
            return result.filePaths[0]?.split(path.sep)?.join(path.posix.sep);
        }
    });

    ipcMain.handle("show-upload-files-dialog", async () => {
        const files = await dialog.showOpenDialog({
            properties: ["openFile", "multiSelections"],
        });
        return files.filePaths;
    });

    ipcMain.handle("show-upload-zip-dialog", async () => {
        const files = await dialog.showOpenDialog({
            properties: ["openFile", "multiSelections"],
            filters: [{ name: "Zip File", extensions: ["zip"] }],
        });
        return files.filePaths;
    });

    ipcMain.handle("show-upload-dirs-dialog", async () => {
        const dir = await dialog.showOpenDialog({
            properties: ["openDirectory", "multiSelections"],
        });

        let files: string[] = [];
        for (const dirPath of dir.filePaths) {
            files = [...files, ...(await getDirFilePaths(dirPath))];
        }

        return files;
    });

    ipcMain.handle("add-watcher", async (_, args: { dir: string }) => {
        watcher.add(args.dir);
    });

    ipcMain.handle("remove-watcher", async (_, args: { dir: string }) => {
        watcher.unwatch(args.dir);
    });

    ipcMain.handle("convert-to-jpeg", (_, fileData, filename) => {
        return convertToJPEG(fileData, filename);
    });

    ipcMain.handle("get-temp-file-path", (_, formatSuffix) => {
        return generateTempFilePath(formatSuffix);
    });
    ipcMain.handle("remove-temp-file", (_, tempFilePath: string) => {
        return deleteTempFile(tempFilePath);
    });

    ipcMain.handle(
        "generate-image-thumbnail",
        (_, fileData, maxDimension, maxSize) => {
            return generateImageThumbnail(fileData, maxDimension, maxSize);
        },
    );

    ipcMain.handle("compute-image-embedding", (_, model, inputFilePath) => {
        return computeImageEmbedding(model, inputFilePath);
    });
    ipcMain.handle("compute-text-embedding", (_, model, text) => {
        return computeTextEmbedding(model, text);
    });
}
