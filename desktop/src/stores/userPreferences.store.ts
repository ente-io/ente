import Store, { Schema } from 'electron-store';
import { UserPreferencesType } from '../types';

const userPreferencesSchema: Schema<UserPreferencesType> = {
    hideDockIcon: {
        type: 'boolean',
    },
    skipAppVersion: {
        type: 'string',
    },
    muteUpdateNotificationVersion: {
        type: 'string',
    },
    optOutOfCrashReports: {
        type: 'boolean',
    },
    customCacheDirectory: {
        type: 'string',
    },
};

export const userPreferencesStore = new Store({
    name: 'userPreferences',
    schema: userPreferencesSchema,
});
