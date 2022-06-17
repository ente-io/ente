import { ipcRenderer } from 'electron/renderer';
import { logError } from '../utils/logging';
import { keysStore, uploadStatusStore, watchStore } from '../services/store';

export const selectRootDirectory = async () => {
    try {
        return await ipcRenderer.invoke('select-dir');
    } catch (e) {
        logError(e, 'error while selecting root directory');
    }
};

export const clearElectronStore = () => {
    try {
        watchStore.clear();
        uploadStatusStore.clear();
        keysStore.clear();
    } catch (e) {
        logError(e, 'error while clearing electron store');
    }
};
