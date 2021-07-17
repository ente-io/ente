import { Menu, app, shell, BrowserWindow, globalShortcut } from "electron";
import { setIsAppQuitting } from "../main";

export function buildContextMenu(mainWindow: BrowserWindow, args: any = {}): Menu {
    const { export_progress, retry_export, paused } = args
    const contextMenu = Menu.buildFromTemplate([
        ...(export_progress
            ? [
                {
                    label: export_progress,
                    click: () => mainWindow.show(),
                },
                ...(paused ?
                    [{
                        label: 'resume export',
                        click: () => mainWindow.webContents.send('resume-export'),
                    }] :
                    [{
                        label: 'pause export',
                        click: () => mainWindow.webContents.send('pause-export'),
                    },
                    {
                        label: 'stop export',
                        click: () => mainWindow.webContents.send('stop-export'),
                    }]
                )
            ]
            : []),
        ...(retry_export
            ? [
                {
                    label: 'export failed',
                    click: null,
                },
                {
                    label: 'retry export',
                    click: () => mainWindow.webContents.send('retry-export'),
                },
            ]
            : []
        ),
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
                setIsAppQuitting(true)
                app.quit();
            },
        },
    ]);
    return contextMenu;
}

export function buildMenuBar(): Menu {
    const isMac = process.platform === 'darwin'

    const commonMenuItem = [{
        label: 'faq',
        click: () => shell.openExternal('https://ente.io/faq/'),
    },
    {
        label: 'support',
        toolTip: 'ente.io web client ',
        click: () => shell.openExternal('mailto:contact@ente.io'),
    },
    {
        label: 'quit',
        accelerator: 'CommandOrControl+Q',
        click() { setIsAppQuitting(true); app.quit(); }
    }]

    return isMac ? Menu.buildFromTemplate([
        {
            label: app.name,
            submenu: [
                { role: 'about' }
                , ...commonMenuItem]
        },
    ]) : Menu.buildFromTemplate([{
        label: app.getName(),
        submenu: commonMenuItem,
    }]);
}

export function configureGlobalShortcuts(mainWindow: BrowserWindow): void {
    globalShortcut.register('CommandOrControl+R', () => { mainWindow.reload() })
    globalShortcut.register('Shift+CommandOrControl+R', () => { mainWindow.webContents.reloadIgnoringCache() })
}
