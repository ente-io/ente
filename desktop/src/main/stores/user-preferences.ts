import Store, { Schema } from "electron-store";

interface UserPreferences {
    hideDockIcon?: boolean;
    skipAppVersion?: string;
    muteUpdateNotificationVersion?: string;
    /**
     * The last position size of our app's window, saved when the app is closed.
     *
     * This value is saved when the app is about to quit, and is used to restore
     * the window to the previous state when it restarts.
     *
     * If the user maximizes the window then this value is cleared and instead
     * we just re-maximize the window on restart. This is also the behaviour if
     * no previously saved `windowRect` is found.
     */
    windowRect?: {
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
    windowRect: {
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
