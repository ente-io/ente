import {
    app,
    BrowserWindow,
    Menu,
    Tray,
    Notification,
    shell,
    dialog,
    ipcMain,
} from 'electron';
import * as path from 'path';
import * as isDev from 'electron-is-dev';

let appIsQuitting = false;
let tray: Tray;
let mainWindow: BrowserWindow;
function createWindow() {
    // Create the browser window.
    const mainWindow = new BrowserWindow({
        height: 600,
        width: 800,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
        },
    });
    mainWindow.setMenu(buildMenuBar());

    if (isDev) {
        mainWindow.loadURL('http://localhost:3000');
        // Open the DevTools.
        mainWindow.webContents.openDevTools();
    } else {
        mainWindow.loadURL('http://photos.ente.io');
    }
    mainWindow.on('minimize', function (event: any) {
        event.preventDefault();
        mainWindow.hide();
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
    mainWindow = createWindow();

    app.on('activate', function () {
        // On macOS it's common to re-create a window in the app when the
        // dock icon is clicked and there are no other windows open.
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
    tray = new Tray('resources/ente.png');
    tray.setToolTip('ente');
    tray.setContextMenu(buildContextMenu());
});

ipcMain.on('select-dir', async (event) => {
    let dialogWindow = new BrowserWindow({
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
        title: 'electron frame | ente.io desktop-app',
        body: args,
    };
    new Notification(notification).show();
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
            label: '   ',
            enabled: false,
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
