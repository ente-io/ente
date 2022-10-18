import { keysStore } from '../stores/keys.store';
import { safeStorageStore } from '../stores/safeStorage.store';
import { uploadStatusStore } from '../stores/upload.store';
import { logError } from '../services/logging';

export const clearElectronStore = () => {
    try {
        uploadStatusStore.clear();
        keysStore.clear();
        safeStorageStore.clear();
    } catch (e) {
        logError(e, 'error while clearing electron store');
        throw e;
    }
};
