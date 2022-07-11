import {
    uploadStatusStore,
    keysStore,
    safeStorageStore,
} from '../services/store';

import { logError } from './logging';

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
