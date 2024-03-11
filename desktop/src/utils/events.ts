import { BrowserWindow } from "electron";

export function setupAppEventEmitter(mainWindow: BrowserWindow) {
    // fire event when mainWindow is in foreground
    mainWindow.on("focus", () => {
        mainWindow.webContents.send("app-in-foreground");
    });
}
