import Store, { Schema } from 'electron-store';
import { UserPreferencesType } from '../types';

const userPreferencesSchema: Schema<UserPreferencesType> = {
    hideDockIcon: {
        type: 'boolean',
    },
};

export const userPreferencesStore = new Store({
    name: 'userPreferences',
    schema: userPreferencesSchema,
});
