import Store, { Schema } from "electron-store";
import type { UserPreferencesType } from "../types/main";

const userPreferencesSchema: Schema<UserPreferencesType> = {
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
