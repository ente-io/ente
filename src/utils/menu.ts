import {
    Menu,
    app,
    shell,
    BrowserWindow,
    MenuItemConstructorOptions,
} from 'electron';
import {
    getHideDockIconPreference,
    setHideDockIconPreference,
} from '../services/userPreference';
import { isUpdateAvailable, setIsAppQuitting } from '../main';
import { showUpdateDialog } from '../services/appUpdater';
import { isPlatformMac } from './main';

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
    const isMac = isPlatformMac();
    let shouldHideDockIcon = getHideDockIconPreference();
    const template: MenuItemConstructorOptions[] = [
        {
            label: 'ente',
            submenu: [
                ...((isMac
                    ? [
                          {
                              label: 'About ente',
                              role: 'about',
                          },
                      ]
                    : []) as MenuItemConstructorOptions[]),
                { type: 'separator' },
                {
                    label: 'Preferences',
                    submenu: [
                        {
                            label: 'Hide dock icon',
                            type: 'checkbox',
                            checked: shouldHideDockIcon,
                            click: () => {
                                setHideDockIconPreference(!shouldHideDockIcon);
                                shouldHideDockIcon = !shouldHideDockIcon;
                            },
                        },
                    ],
                },

                { type: 'separator' },
                ...((isMac
                    ? [
                          {
                              label: 'Hide ente',
                              role: 'hide',
                          },
                          {
                              label: 'Hide others',
                              role: 'hideOthers',
                          },
                      ]
                    : []) as MenuItemConstructorOptions[]),

                { type: 'separator' },
                {
                    label: 'Quit ente',
                    role: 'quit',
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
        {
            label: 'View',
            submenu: [
                { role: 'resetZoom', label: 'Reset zoom' },
                { role: 'zoomIn', label: 'Zoom in' },
                { role: 'zoomOut', label: 'Zoom out' },
                { type: 'separator' },
                { role: 'togglefullscreen', label: 'Toggle fullscreen' },
            ],
        },
        {
            label: 'Window',
            submenu: [
                { role: 'minimize', label: 'Minimize' },
                ...((isMac
                    ? [
                          { type: 'separator' },
                          { role: 'front', label: 'Bring to front' },
                          { type: 'separator' },
                          { role: 'window', label: 'ente' },
                      ]
                    : [
                          { role: 'close', label: 'Close ente' },
                      ]) as MenuItemConstructorOptions[]),
            ],
        },
        {
            label: 'Help',
            submenu: [
                {
                    label: 'FAQ',
                    click: () => shell.openExternal('https://ente.io/faq/'),
                },
                { type: 'separator' },
                {
                    label: 'Support',
                    click: () => shell.openExternal('mailto:support@ente.io'),
                },
                {
                    label: 'Product updates',
                    click: () => shell.openExternal('https://ente.io/blog/'),
                },
            ],
        },
    ];
    return Menu.buildFromTemplate(template);
}
