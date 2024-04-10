import Store, { Schema } from "electron-store";

interface UserPreferencesSchema {
    hideDockIcon: boolean;
    skipAppVersion?: string;
    muteUpdateNotificationVersion?: string;
}

const userPreferencesSchema: Schema<UserPreferencesSchema> = {
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

export const userPreferencesStore = new Store({
    name: "userPreferences",
    schema: userPreferencesSchema,
});
