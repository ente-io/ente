import Store, { Schema } from "electron-store";

interface UserPreferences {
    hideDockIcon: boolean;
    skipAppVersion?: string;
    muteUpdateNotificationVersion?: string;
}

const userPreferencesSchema: Schema<UserPreferences> = {
    hideDockIcon: {
        type: "boolean",
    },
    skipAppVersion: {
        type: "string",
    },
    muteUpdateNotificationVersion: {
        type: "string",
    },
};

export const userPreferences = new Store({
    name: "userPreferences",
    schema: userPreferencesSchema,
});
