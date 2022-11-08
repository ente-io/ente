import { ipcRenderer } from 'electron/renderer';
import { logError } from '../services/logging';

export const selectRootDirectory = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke('select-dir');
    } catch (e) {
        logError(e, 'error while selecting root directory');
    }
};

export { logToDisk, openLogDirectory } from '../services/logging';

export { getSentryUserID } from '../services/sentry';
