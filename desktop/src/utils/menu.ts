import {
    app,
    BrowserWindow,
    Menu,
    MenuItemConstructorOptions,
    shell,
} from "electron";
import ElectronLog from "electron-log";
import { setIsAppQuitting } from "../main";
import { forceCheckForUpdateAndNotify } from "../services/appUpdater";
import autoLauncher from "../services/autoLauncher";
import {
    getHideDockIconPreference,
    setHideDockIconPreference,
} from "../services/userPreference";
import { isPlatform } from "./common/platform";

export function buildContextMenu(mainWindow: BrowserWindow): Menu {
    // eslint-disable-next-line camelcase
    const contextMenu = Menu.buildFromTemplate([
        {
            label: "Open ente",
            click: function () {
                mainWindow.maximize();
                mainWindow.show();
            },
        },
        {
            label: "Quit ente",
            click: function () {
                ElectronLog.log("user quit the app");
                setIsAppQuitting(true);
                app.quit();
            },
        },
    ]);
    return contextMenu;
}

export async function buildMenuBar(mainWindow: BrowserWindow): Promise<Menu> {
    let isAutoLaunchEnabled = await autoLauncher.isEnabled();
    const isMac = isPlatform("mac");
    let shouldHideDockIcon = getHideDockIconPreference();
    const template: MenuItemConstructorOptions[] = [
        {
            label: "ente",
            submenu: [
                ...((isMac
                    ? [
                          {
                              label: "About ente",
                              role: "about",
                          },
                      ]
                    : []) as MenuItemConstructorOptions[]),
                { type: "separator" },
                {
                    label: "Check for updates...",
                    click: () => {
                        forceCheckForUpdateAndNotify(mainWindow);
                    },
                },
                {
                    label: "View Changelog",
                    click: () => {
                        shell.openExternal(
                            "https://github.com/ente-io/ente/blob/main/desktop/CHANGELOG.md",
                        );
                    },
                },
                { type: "separator" },

                {
                    label: "Preferences",
                    submenu: [
                        {
                            label: "Open ente on startup",
                            type: "checkbox",
                            checked: isAutoLaunchEnabled,
                            click: () => {
                                autoLauncher.toggleAutoLaunch();
                                isAutoLaunchEnabled = !isAutoLaunchEnabled;
                            },
                        },
                        {
                            label: "Hide dock icon",
                            type: "checkbox",
                            checked: shouldHideDockIcon,
                            click: () => {
                                setHideDockIconPreference(!shouldHideDockIcon);
                                shouldHideDockIcon = !shouldHideDockIcon;
                            },
                        },
                    ],
                },

                { type: "separator" },
                ...((isMac
                    ? [
                          {
                              label: "Hide ente",
                              role: "hide",
                          },
                          {
                              label: "Hide others",
                              role: "hideOthers",
                          },
                      ]
                    : []) as MenuItemConstructorOptions[]),

                { type: "separator" },
                {
                    label: "Quit ente",
                    role: "quit",
                },
            ],
        },
        {
            label: "Edit",
            submenu: [
                { role: "undo", label: "Undo" },
                { role: "redo", label: "Redo" },
                { type: "separator" },
                { role: "cut", label: "Cut" },
                { role: "copy", label: "Copy" },
                { role: "paste", label: "Paste" },
                ...((isMac
                    ? [
                          {
                              role: "pasteAndMatchStyle",
                              label: "Paste and match style",
                          },
                          { role: "delete", label: "Delete" },
                          { role: "selectAll", label: "Select all" },
                          { type: "separator" },
                          {
                              label: "Speech",
                              submenu: [
                                  {
                                      role: "startSpeaking",
                                      label: "start speaking",
                                  },
                                  {
                                      role: "stopSpeaking",
                                      label: "stop speaking",
                                  },
                              ],
                          },
                      ]
                    : [
                          { type: "separator" },
                          { role: "selectAll", label: "Select all" },
                      ]) as MenuItemConstructorOptions[]),
            ],
        },
        {
            label: "View",
            submenu: [
                { role: "reload", label: "Reload" },
                { role: "forceReload", label: "Force reload" },
                { role: "toggleDevTools", label: "Toggle dev tools" },
                { type: "separator" },
                { role: "resetZoom", label: "Reset zoom" },
                { role: "zoomIn", label: "Zoom in" },
                { role: "zoomOut", label: "Zoom out" },
                { type: "separator" },
                { role: "togglefullscreen", label: "Toggle fullscreen" },
            ],
        },
        {
            label: "Window",
            submenu: [
                { role: "close", label: "Close" },
                { role: "minimize", label: "Minimize" },
                ...((isMac
                    ? [
                          { type: "separator" },
                          { role: "front", label: "Bring to front" },
                          { type: "separator" },
                          { role: "window", label: "ente" },
                      ]
                    : []) as MenuItemConstructorOptions[]),
            ],
        },
        {
            label: "Help",
            submenu: [
                {
                    label: "FAQ",
                    click: () => shell.openExternal("https://ente.io/faq/"),
                },
                { type: "separator" },
                {
                    label: "Support",
                    click: () => shell.openExternal("mailto:support@ente.io"),
                },
                {
                    label: "Product updates",
                    click: () => shell.openExternal("https://ente.io/blog/"),
                },
                { type: "separator" },
                {
                    label: "View crash reports",
                    click: () => {
                        shell.openPath(app.getPath("crashDumps"));
                    },
                },
                {
                    label: "View logs",
                    click: () => {
                        shell.openPath(app.getPath("logs"));
                    },
                },
            ],
        },
    ];
    return Menu.buildFromTemplate(template);
}
