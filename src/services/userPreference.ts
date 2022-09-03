import { userPreferencesStore } from './store';

export function getHideDockIconPreference() {
    const shouldHideDockIcon = userPreferencesStore.get('hideDockIcon');
    return shouldHideDockIcon;
}

export function setHideDockIconPreference(shouldHideDockIcon: boolean) {
    userPreferencesStore.set('hideDockIcon', shouldHideDockIcon);
}
