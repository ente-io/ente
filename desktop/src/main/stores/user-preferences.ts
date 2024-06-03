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
     * The last position and size of our app's window.
     *
     * This value is saved when the app is about to quit, and is used to restore
     * the window to the previous state when it restarts.
     *
     * If the user maximizes the window then this value is cleared and instead
     * we just re-maximize the window on restart. This is also the behaviour if
     * no previously saved `windowRect` is found.
     */
    windowBounds?: {
        x: number;
        y: number;
        width: number;
        height: number;
    };
}

const userPreferencesSchema: Schema<UserPreferences> = {
    hideDockIcon: { type: "boolean" },
    skipAppVersion: { type: "string" },
    muteUpdateNotificationVersion: { type: "string" },
    windowBounds: {
        properties: {
            x: { type: "number" },
            y: { type: "number" },
            width: { type: "number" },
            height: { type: "number" },
        },
    },
};

export const userPreferences = new Store({
    name: "userPreferences",
    schema: userPreferencesSchema,
});
