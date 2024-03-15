import { ipcRenderer } from "electron/renderer";
import { logError } from "../services/logging";

export const selectDirectory = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke("select-dir");
    } catch (e) {
        logError(e, "error while selecting root directory");
    }
};

export const getAppVersion = async (): Promise<string> => {
    try {
        return await ipcRenderer.invoke("get-app-version");
    } catch (e) {
        logError(e, "failed to get release version");
        throw e;
    }
};

export const openDirectory = async (dirPath: string): Promise<void> => {
    try {
        await ipcRenderer.invoke("open-dir", dirPath);
    } catch (e) {
        logError(e, "error while opening directory");
        throw e;
    }
};

export { logToDisk, openLogDirectory } from "../services/logging";
