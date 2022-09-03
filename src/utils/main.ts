import { nativeImage, Tray, app, BrowserWindow, Menu } from 'electron';
import path from 'path';
import { existsSync } from 'promise-fs';
import appUpdater from './appUpdater';
import { isDev } from './common';
import { buildContextMenu, buildMenuBar } from './menu';

export function handleUpdates(mainWindow: BrowserWindow, tray: Tray) {
    if (!isDev) {
        appUpdater.checkForUpdate(tray, mainWindow);
    }
}

export function setupTrayItem(mainWindow: BrowserWindow) {
    const trayImgPath = isDev
        ? 'build/taskbar-icon.png'
        : path.join(process.resourcesPath, 'taskbar-icon.png');
    const trayIcon = nativeImage.createFromPath(trayImgPath);
    const tray = new Tray(trayIcon);
    tray.setToolTip('ente');
    tray.setContextMenu(buildContextMenu(mainWindow));
    return tray;
}

export function handleDownloads(mainWindow: BrowserWindow) {
    mainWindow.webContents.session.on('will-download', (_, item) => {
        item.setSavePath(
            getUniqueSavePath(item.getFilename(), app.getPath('downloads'))
        );
    });
}

export function getUniqueSavePath(filename: string, directory: string): string {
    let uniqueFileSavePath = path.join(directory, filename);
    const { name: filenameWithoutExtension, ext: extension } =
        path.parse(filename);
    let n = 0;
    while (existsSync(uniqueFileSavePath)) {
        n++;
        // filter need to remove undefined extension from the array
        // else [`${fileName}`, undefined].join(".") will lead to `${fileName}.` as joined string
        const fileNameWithNumberedSuffix = [
            `${filenameWithoutExtension}(${n})`,
            extension,
        ]
            .filter((x) => x) // filters out undefined/null values
            .join('.');
        uniqueFileSavePath = path.join(directory, fileNameWithNumberedSuffix);
    }
    return uniqueFileSavePath;
}

export function setupMacWindowOnDockIconClick() {
    app.on('activate', function () {
        const windows = BrowserWindow.getAllWindows();
        // we allow only one window
        windows[0].show();
    });
}

export function setupMainMenu() {
    Menu.setApplicationMenu(buildMenuBar());
}

export function isPlatformMac() {
    return process.platform === 'darwin';
}
