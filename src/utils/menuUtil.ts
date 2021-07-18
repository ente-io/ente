import { Menu, app, shell, BrowserWindow, MenuItemConstructorOptions } from "electron";
import { isUpdateAvailable, setIsAppQuitting } from "../main";
import { showUpdateDialog } from "./appUpdater";


const isMac = process.platform === 'darwin'

export function buildContextMenu(mainWindow: BrowserWindow, args: any = {}): Menu {
    const { export_progress, retry_export, paused } = args
    const contextMenu = Menu.buildFromTemplate([
        ...(isUpdateAvailable() && [{
            label: 'update available',
            click: () => showUpdateDialog()
        }]),
        { type: 'separator' },
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
                const isMac = process.platform === 'darwin'
                isMac && app.dock.show();
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
    const template: MenuItemConstructorOptions[]=[
        {
            label:app.name,
            submenu:[...(isMac &&[
                { 
                 label: "about" ,
                 role: 'about'
                }]) as MenuItemConstructorOptions[],
                {
                    label: 'faq',
                    click: () => shell.openExternal('https://ente.io/faq/'),
                },
                {
                    label: 'support',
                    click: () => shell.openExternal('mailto:support@ente.io'),
                },
                {
                    label: 'quit',
                    accelerator: 'CommandOrControl+Q',
                    click() { setIsAppQuitting(true); app.quit(); }
                }
            ]
        },
        {
            label: 'edit',
            submenu: [
              { role: 'undo',label:"undo" },
              { role: 'redo' ,label:"redo"},
              { type: 'separator'},
              { role: 'cut' ,label:"cut"},
              { role: 'copy' ,label:"copy"},
              { role: 'paste' ,label:"paste"},
              ...(isMac ?[
                { role: 'pasteAndMatchStyle' ,label:"paste and match style"},
                { role: 'delete' ,label:"delete"},
                { role: 'selectAll' ,label:"select all"},
                { type: 'separator'},
                {
                  label: 'speech',
                  submenu: [
                    { role: 'startSpeaking' ,label:"start speaking"},
                    { role: 'stopSpeaking' ,label:"stop speaking"}
                  ]
                }
              ] : [
                { type: 'separator' },
                { role: 'selectAll',label:"select all" }
              ])as MenuItemConstructorOptions[]
            ]
        },
          // { role: 'viewMenu' }
          {
            label: 'view',
            submenu: [
              { role: 'reload',label:"reload" },
              { role: 'forceReload',label:"force reload" },
              { role: 'toggleDevTools' ,label:"toggle devTools"},
              { type: 'separator' },
              { role: 'resetZoom',label:"reset zoom" },
              { role: 'zoomIn',label:"zoom in" },
              { role: 'zoomOut' ,label:"zoom out"},
              { type: 'separator' },
              { role: 'togglefullscreen' ,label:"toggle fullscreen"}
            ]
          },
          // { role: 'windowMenu' }
          {
            label: 'window',
            submenu: [
              { role: 'minimize' ,label:"minimize"},
              ...(isMac ? [
                { type: 'separator'},
                { role: 'front',label:"front" },
                { type: 'separator' },
                { role: 'window' ,label:"window"}
              ] : [
                { role: 'close' ,label:"close"}
              ])as MenuItemConstructorOptions[]
            ]
          },

    ]
    return Menu.buildFromTemplate(template)
}
