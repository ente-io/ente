import {
    app,
    BrowserWindow,
    Menu,
    MenuItemConstructorOptions,
    shell,
} from "electron";
import { setIsAppQuitting } from "../main";
import { forceCheckForUpdateAndNotify } from "../services/appUpdater";
import autoLauncher from "../services/autoLauncher";
import {
    getHideDockIconPreference,
    setHideDockIconPreference,
} from "../services/userPreference";
import { openLogDirectory } from "./util";

/** Create and return the entries in the app's main menu bar */
export const createApplicationMenu = async (mainWindow: BrowserWindow) => {
    // The state of checkboxes
    //
    // Whenever the menu is redrawn the current value of these variables is used
    // to set the checked state for the various settings checkboxes.
    let isAutoLaunchEnabled = await autoLauncher.isEnabled();
    let shouldHideDockIcon = getHideDockIconPreference();

    const macOSOnly = (options: MenuItemConstructorOptions[]) =>
        process.platform == "darwin" ? options : [];

    const handleCheckForUpdates = () =>
        forceCheckForUpdateAndNotify(mainWindow);

    const handleViewChangelog = () =>
        shell.openExternal(
            "https://github.com/ente-io/ente/blob/main/desktop/CHANGELOG.md",
        );

    const toggleAutoLaunch = () => {
        autoLauncher.toggleAutoLaunch();
        isAutoLaunchEnabled = !isAutoLaunchEnabled;
    };

    const toggleHideDockIcon = () => {
        setHideDockIconPreference(!shouldHideDockIcon);
        shouldHideDockIcon = !shouldHideDockIcon;
    };

    const handleHelp = () => shell.openExternal("https://help.ente.io/photos/");

    const handleSupport = () => shell.openExternal("mailto:support@ente.io");

    const handleBlog = () => shell.openExternal("https://ente.io/blog/");

    const handleViewLogs = openLogDirectory;

    return Menu.buildFromTemplate([
        {
            label: "ente",
            submenu: [
                ...macOSOnly([
                    {
                        label: "About Ente",
                        role: "about",
                    },
                ]),
                { type: "separator" },
                {
                    label: "Check for Updates...",
                    click: handleCheckForUpdates,
                },
                {
                    label: "View Changelog",
                    click: handleViewChangelog,
                },
                { type: "separator" },

                {
                    label: "Preferences",
                    submenu: [
                        {
                            label: "Open Ente on Startup",
                            type: "checkbox",
                            checked: isAutoLaunchEnabled,
                            click: toggleAutoLaunch,
                        },
                        {
                            label: "Hide Dock Icon",
                            type: "checkbox",
                            checked: shouldHideDockIcon,
                            click: toggleHideDockIcon,
                        },
                    ],
                },

                { type: "separator" },
                ...macOSOnly([
                    {
                        label: "Hide Ente",
                        role: "hide",
                    },
                    {
                        label: "Hide Others",
                        role: "hideOthers",
                    },
                    { type: "separator" },
                ]),
                {
                    label: "Quit",
                    role: "quit",
                },
            ],
        },
        {
            label: "Edit",
            submenu: [
                { label: "Undo", role: "undo" },
                { label: "Redo", role: "redo" },
                { type: "separator" },
                { label: "Cut", role: "cut" },
                { label: "Copy", role: "copy" },
                { label: "Paste", role: "paste" },
                { label: "Select All", role: "selectAll" },
                ...macOSOnly([
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
                ]),
            ],
        },
        {
            label: "View",
            submenu: [
                { label: "Reload", role: "reload" },
                { label: "Toggle Dev Tools", role: "toggleDevTools" },
                { type: "separator" },
                { label: "Toggle Full Screen", role: "togglefullscreen" },
            ],
        },
        {
            label: "Window",
            submenu: [
                { label: "Minimize", role: "minimize" },
                { label: "Zoom", role: "zoom" },
                { label: "Close", role: "close" },
                ...macOSOnly([
                    { type: "separator" },
                    { label: "Bring All to Front", role: "front" },
                    { type: "separator" },
                    { label: "Ente", role: "window" },
                ]),
            ],
        },
        {
            label: "Help",
            submenu: [
                {
                    label: "Ente Help",
                    click: handleHelp,
                },
                { type: "separator" },
                {
                    label: "Support",
                    click: handleSupport,
                },
                {
                    label: "Product Updates",
                    click: handleBlog,
                },
                { type: "separator" },
                {
                    label: "View Logs",
                    click: handleViewLogs,
                },
            ],
        },
    ]);
};

/**
 * Create and return a {@link Menu} that is shown when the user clicks on our
 * system tray icon (e.g. the icon list at the top right of the screen on macOS)
 */
export const createTrayContextMenu = (mainWindow: BrowserWindow) => {
    const handleOpen = () => {
        mainWindow.maximize();
        mainWindow.show();
    };

    const handleClose = () => {
        setIsAppQuitting(true);
        app.quit();
    };

    return Menu.buildFromTemplate([
        {
            label: "Open Ente",
            click: handleOpen,
        },
        {
            label: "Quit Ente",
            click: handleClose,
        },
    ]);
};
