import {
    app,
    BrowserWindow,
    Menu,
    Tray,
    Notification,
    shell,
    dialog,
    ipcMain,
    nativeImage,
} from 'electron';
import * as path from 'path';
import * as isDev from 'electron-is-dev';
import { autoUpdater } from 'electron-updater';

let appIsQuitting = false;
let tray: Tray;
let mainWindow: BrowserWindow;

function createWindow() {
    const appImgPath = isDev
        ? 'build/window-icon.png'
        : path.join(process.resourcesPath, 'window-icon.png');
    const appIcon = nativeImage.createFromPath(appImgPath);
    // Create the browser window.
    const mainWindow = new BrowserWindow({
        height: 600,
        width: 800,
        backgroundColor: '#111111',
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
        },
        icon: appIcon,
        show: false, // don't show the main window
    });
    mainWindow.setMenu(buildMenuBar());
    const splash = new BrowserWindow({
        frame: false,
        alwaysOnTop: true,
        height: 600,
        width: 800,
        transparent: true,
    });

    if (isDev) {
        splash.loadFile(`../build/splash.html`);
        mainWindow.loadURL('http://localhost:3000');
        // Open the DevTools.
        mainWindow.webContents.openDevTools();
    } else {
        splash.loadURL(
            `file://${path.join(process.resourcesPath, 'splash.html')}`
        );
        mainWindow.loadURL('http://photos.ente.io');
    }
    mainWindow.webContents.on('did-fail-load', () => {
        splash.close();
        mainWindow.show();
        isDev
            ? mainWindow.loadFile(`../build/error.html`)
            : splash.loadURL(
                `file://${path.join(process.resourcesPath, 'error.html')}`
            );
    });
    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
        splash.destroy();
    });
    mainWindow.on('close', function (event) {
        if (!appIsQuitting) {
            event.preventDefault();
            mainWindow.hide();
        }
        return false;
    });
    return mainWindow;
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', () => {
    if (!isDev) {
        autoUpdater.checkForUpdatesAndNotify();
    }
    mainWindow = createWindow();

    app.on('activate', function () {
        // On macOS it's common to re-create a window in the app when the
        // dock icon is clicked and there are no other windows open.
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
    const trayImgPath = isDev
        ? 'build/taskbar-icon.png'
        : path.join(process.resourcesPath, 'taskbar-icon.png');
    const trayIcon = nativeImage.createFromPath(trayImgPath);
    tray = new Tray(trayIcon);
    tray.setToolTip('ente');
    tray.setContextMenu(buildContextMenu());
});

ipcMain.on('select-dir', async (event) => {
    const dialogWindow = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            nodeIntegration: false,
            enableRemoteModule: false,
            contextIsolation: true,
            sandbox: true,
        },
    });
    const result = await dialog.showOpenDialog(dialogWindow, {
        properties: ['openDirectory'],
    });
    const dir =
        result.filePaths && result.filePaths.length > 0 && result.filePaths[0];
    dialogWindow.close();
    event.returnValue = dir;
});

ipcMain.on('update-tray', (event, args) => {
    tray.setContextMenu(buildContextMenu(args));
});

ipcMain.on('send-notification', (event, args) => {
    const notification = {
        title: 'ente',
        body: args,
    };
    new Notification(notification).show();
});
ipcMain.on('reload-window', (event, args) => {
    const secondWindow = createWindow();
    mainWindow.destroy();
    mainWindow = secondWindow;
});

function buildContextMenu(export_progress: any = null) {
    const contextMenu = Menu.buildFromTemplate([
        ...(export_progress
            ? [
                {
                    label: export_progress,
                    click: () => mainWindow.show(),
                },
                {
                    label: 'stop export',
                    click: () => mainWindow.webContents.send('stop-export'),
                },
            ]
            : []),
        { type: 'separator' },
        {
            label: 'open ente',
            click: function () {
                mainWindow.show();
            },
        },
        {
            label: 'quit ente',
            click: function () {
                appIsQuitting = true;
                app.quit();
            },
        },
    ]);
    return contextMenu;
}

function buildMenuBar() {
    return Menu.buildFromTemplate([
        {
            label: '  ',
            accelerator: 'CmdOrCtrl+R',
            click() {
                mainWindow.reload();
            },
        },
        {
            label: 'help',
            submenu: Menu.buildFromTemplate([
                {
                    label: 'faq',
                    click: () => shell.openExternal('https://ente.io/faq/'),
                },
                {
                    label: 'support',
                    toolTip: 'ente.io web client ',
                    click: () => shell.openExternal('mailto:contact@ente.io'),
                },
            ]),
        },
    ]);
}
