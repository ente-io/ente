import { logError } from "../main/log";
import { keysStore } from "../stores/keys.store";
import { safeStorageStore } from "../stores/safeStorage.store";
import { uploadStatusStore } from "../stores/upload.store";
import { watchStore } from "../stores/watch.store";

export const clearElectronStore = () => {
    try {
        uploadStatusStore.clear();
        keysStore.clear();
        safeStorageStore.clear();
        watchStore.clear();
    } catch (e) {
        logError(e, "error while clearing electron store");
        throw e;
    }
};
