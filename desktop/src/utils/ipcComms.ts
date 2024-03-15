import chokidar from "chokidar";
import {
    app,
    BrowserWindow,
    dialog,
    ipcMain,
    Notification,
    safeStorage,
    shell,
    Tray,
} from "electron";
import path from "path";
import {
    getAppVersion,
    muteUpdateNotification,
    skipAppUpdate,
    updateAndRestart,
} from "../services/appUpdater";
import {
    computeImageEmbedding,
    computeTextEmbedding,
} from "../services/clipService";
import { deleteTempFile, runFFmpegCmd } from "../services/ffmpeg";
import { getDirFilePaths } from "../services/fs";
import {
    convertToJPEG,
    generateImageThumbnail,
} from "../services/imageProcessor";
import { logErrorSentry } from "../services/sentry";
import { createWindow } from "./createWindow";
import { generateTempFilePath } from "./temp";

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow,
    watcher: chokidar.FSWatcher,
): void {
    ipcMain.handle("select-dir", async () => {
        const result = await dialog.showOpenDialog({
            properties: ["openDirectory"],
        });
        if (result.filePaths && result.filePaths.length > 0) {
            return result.filePaths[0]?.split(path.sep)?.join(path.posix.sep);
        }
    });

    ipcMain.on("send-notification", (_, args) => {
        const notification = {
            title: "ente",
            body: args,
        };
        new Notification(notification).show();
    });
    ipcMain.on("reload-window", async () => {
        const secondWindow = await createWindow();
        mainWindow.destroy();
        mainWindow = secondWindow;
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

    ipcMain.handle("log-error", (_, err, msg, info?) => {
        logErrorSentry(err, msg, info);
    });

    ipcMain.handle("safeStorage-encrypt", (_, message) => {
        return safeStorage.encryptString(message);
    });

    ipcMain.handle("safeStorage-decrypt", (_, message) => {
        return safeStorage.decryptString(message);
    });

    ipcMain.handle("get-path", (_, message) => {
        // By default, these paths are at the following locations:
        //
        // * macOS: `~/Library/Application Support/ente`
        // * Linux: `~/.config/ente`
        // * Windows: `%APPDATA%`, e.g. `C:\Users\<username>\AppData\Local\ente`
        // * Windows: C:\Users\<you>\AppData\Local\<Your App Name>
        //
        // https://www.electronjs.org/docs/latest/api/app
        return app.getPath(message);
    });

    ipcMain.handle("convert-to-jpeg", (_, fileData, filename) => {
        return convertToJPEG(fileData, filename);
    });

    ipcMain.handle("open-log-dir", () => {
        shell.openPath(app.getPath("logs"));
    });

    ipcMain.handle("open-dir", (_, dirPath) => {
        shell.openPath(path.normalize(dirPath));
    });

    ipcMain.on("update-and-restart", () => {
        updateAndRestart();
    });
    ipcMain.on("skip-app-update", (_, version) => {
        skipAppUpdate(version);
    });

    ipcMain.on("mute-update-notification", (_, version) => {
        muteUpdateNotification(version);
    });

    ipcMain.handle("get-app-version", () => {
        return getAppVersion();
    });

    ipcMain.handle(
        "run-ffmpeg-cmd",
        (_, cmd, inputFilePath, outputFileName, dontTimeout) => {
            return runFFmpegCmd(
                cmd,
                inputFilePath,
                outputFileName,
                dontTimeout,
            );
        },
    );
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
