import chokidar from "chokidar";
import { BrowserWindow, ipcMain, Tray } from "electron";
import { attachIPCHandlers } from "../main/ipc";

export default function setupIpcComs(
    tray: Tray,
    mainWindow: BrowserWindow,
    watcher: chokidar.FSWatcher,
): void {
    attachIPCHandlers();

    ipcMain.handle("add-watcher", async (_, args: { dir: string }) => {
        watcher.add(args.dir);
    });

    ipcMain.handle("remove-watcher", async (_, args: { dir: string }) => {
        watcher.unwatch(args.dir);
    });
}
