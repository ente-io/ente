import { ipcRenderer } from 'electron/renderer';
import { logError } from '../utils/logging';

export const selectRootDirectory = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke('select-dir');
    } catch (e) {
        logError(e, 'error while selecting root directory');
    }
};
