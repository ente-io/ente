import {
    Menu,
    app,
    shell,
    BrowserWindow,
    MenuItemConstructorOptions,
} from 'electron';
import { isUpdateAvailable, setIsAppQuitting } from '..';
import { showUpdateDialog } from './appUpdater';

const isMac = process.platform === 'darwin';

export function buildContextMenu(
    mainWindow: BrowserWindow,
    args: any = {}
): Menu {
    // eslint-disable-next-line camelcase
    const {
        export_progress: exportProgress,
        retry_export: retryExport,
        paused,
    } = args;
    const contextMenu = Menu.buildFromTemplate([
        ...(isUpdateAvailable()
            ? [
                  {
                      label: 'Update available',
                      click: () => showUpdateDialog(),
                  },
              ]
            : []),
        { type: 'separator' },
        ...(exportProgress
            ? [
                  {
                      label: exportProgress,
                      click: () => mainWindow.show(),
                  },
                  ...(paused
                      ? [
                            {
                                label: 'Resume export',
                                click: () =>
                                    mainWindow.webContents.send(
                                        'resume-export'
                                    ),
                            },
                        ]
                      : [
                            {
                                label: 'Pause export',
                                click: () =>
                                    mainWindow.webContents.send('pause-export'),
                            },
                            {
                                label: 'Stop export',
                                click: () =>
                                    mainWindow.webContents.send('stop-export'),
                            },
                        ]),
              ]
            : []),
        ...(retryExport
            ? [
                  {
                      label: 'Export failed',
                      click: null,
                  },
                  {
                      label: 'Retry export',
                      click: () => mainWindow.webContents.send('retry-export'),
                  },
              ]
            : []),
        { type: 'separator' },
        {
            label: 'Open ente',
            click: function () {
                mainWindow.show();
                const isMac = process.platform === 'darwin';
                isMac && app.dock.show();
            },
        },
        {
            label: 'Quit ente',
            click: function () {
                setIsAppQuitting(true);
                app.quit();
            },
        },
    ]);
    return contextMenu;
}

export function buildMenuBar(): Menu {
    const template: MenuItemConstructorOptions[] = [
        {
            label: app.name,
            submenu: [
                ...((isMac
                    ? [
                          {
                              label: 'About',
                              role: 'about',
                          },
                      ]
                    : []) as MenuItemConstructorOptions[]),
                {
                    label: 'FAQ',
                    click: () => shell.openExternal('https://ente.io/faq/'),
                },
                {
                    label: 'Support',
                    click: () => shell.openExternal('mailto:support@ente.io'),
                },
                {
                    label: 'Quit',
                    accelerator: 'CommandOrControl+Q',
                    click() {
                        setIsAppQuitting(true);
                        app.quit();
                    },
                },
            ],
        },
        {
            label: 'Edit',
            submenu: [
                { role: 'undo', label: 'Undo' },
                { role: 'redo', label: 'Redo' },
                { type: 'separator' },
                { role: 'cut', label: 'Cut' },
                { role: 'copy', label: 'Copy' },
                { role: 'paste', label: 'Paste' },
                ...((isMac
                    ? [
                          {
                              role: 'pasteAndMatchStyle',
                              label: 'Paste and match style',
                          },
                          { role: 'delete', label: 'Delete' },
                          { role: 'selectAll', label: 'Select all' },
                          { type: 'separator' },
                          {
                              label: 'Speech',
                              submenu: [
                                  {
                                      role: 'startSpeaking',
                                      label: 'start speaking',
                                  },
                                  {
                                      role: 'stopSpeaking',
                                      label: 'stop speaking',
                                  },
                              ],
                          },
                      ]
                    : [
                          { type: 'separator' },
                          { role: 'selectAll', label: 'Select all' },
                      ]) as MenuItemConstructorOptions[]),
            ],
        },
        // { role: 'viewMenu' }
        {
            label: 'View',
            submenu: [
                { role: 'reload', label: 'Reload' },
                { role: 'forceReload', label: 'Force reload' },
                { role: 'toggleDevTools', label: 'Toggle dev tools' },
                { type: 'separator' },
                { role: 'resetZoom', label: 'Reset zoom' },
                { role: 'zoomIn', label: 'Zoom in' },
                { role: 'zoomOut', label: 'Zoom out' },
                { type: 'separator' },
                { role: 'togglefullscreen', label: 'Toggle fullscreen' },
            ],
        },
        // { role: 'windowMenu' }
        {
            label: 'Window',
            submenu: [
                { role: 'minimize', label: 'Minimize' },
                ...((isMac
                    ? [
                          { type: 'separator' },
                          { role: 'front', label: 'Front' },
                          { type: 'separator' },
                          { role: 'window', label: 'Window' },
                      ]
                    : [
                          { role: 'close', label: 'Close' },
                      ]) as MenuItemConstructorOptions[]),
            ],
        },
    ];
    return Menu.buildFromTemplate(template);
}
