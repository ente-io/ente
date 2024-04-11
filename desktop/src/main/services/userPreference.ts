import { userPreferencesStore } from "../stores/user-preferences";

export function getHideDockIconPreference() {
    return userPreferencesStore.get("hideDockIcon");
}

export function setHideDockIconPreference(shouldHideDockIcon: boolean) {
    userPreferencesStore.set("hideDockIcon", shouldHideDockIcon);
}
