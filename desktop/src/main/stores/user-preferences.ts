import Store, { Schema } from "electron-store";

interface UserPreferences {
    /**
     * If true, then the user has set a preference to also hide the dock icon on
     * macOS whenever the app is hidden. The tray icon is always visible and can
     * then be used to reopen the app when needed.
     */
    hideDockIcon?: boolean;
    skipAppVersion?: string;
    muteUpdateNotificationVersion?: string;
    /**
     * The changelog version for which we last showed the "What's new" screen.
     *
     * See: [Note: Conditions for showing "What's new"]
     */
    lastShownChangelogVersion?: number;
    /**
     * The last position and size of our app's window.
     *
     * This value is saved when the app is about to quit, and is used to restore
     * the window to the previous state when it restarts. It is only saved if
     * the app is not maximized (when the app was maximized when it was being
     * quit then {@link isWindowMaximized} will be set instead).
     */
    windowBounds?: {
        x: number;
        y: number;
        width: number;
        height: number;
    };
    /**
     * `true` if the app's main window is maximized the last time it was closed.
     */
    isWindowMaximized?: boolean;
}

const userPreferencesSchema: Schema<UserPreferences> = {
    hideDockIcon: { type: "boolean" },
    skipAppVersion: { type: "string" },
    muteUpdateNotificationVersion: { type: "string" },
    lastShownChangelogVersion: { type: "number" },
    windowBounds: {
        properties: {
            x: { type: "number" },
            y: { type: "number" },
            width: { type: "number" },
            height: { type: "number" },
        },
    },
    isWindowMaximized: { type: "boolean" },
};

export const userPreferences = new Store({
    name: "userPreferences",
    schema: userPreferencesSchema,
});
