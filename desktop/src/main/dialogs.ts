import { dialog } from "electron/main";
import path from "node:path";
import { getDirFilePaths, getElectronFile } from "../services/fs";
import { getElectronFilesFromGoogleZip } from "../services/upload";
import type { ElectronFile } from "../types/ipc";

export const selectDirectory = async () => {
    const result = await dialog.showOpenDialog({
        properties: ["openDirectory"],
    });
    if (result.filePaths && result.filePaths.length > 0) {
        return result.filePaths[0]?.split(path.sep)?.join(path.posix.sep);
    }
};

export const showUploadFilesDialog = async () => {
    const selectedFiles = await dialog.showOpenDialog({
        properties: ["openFile", "multiSelections"],
    });
    const filePaths = selectedFiles.filePaths;
    return await Promise.all(filePaths.map(getElectronFile));
};

export const showUploadDirsDialog = async () => {
    const dir = await dialog.showOpenDialog({
        properties: ["openDirectory", "multiSelections"],
    });

    let filePaths: string[] = [];
    for (const dirPath of dir.filePaths) {
        filePaths = [...filePaths, ...(await getDirFilePaths(dirPath))];
    }

    return await Promise.all(filePaths.map(getElectronFile));
};

export const showUploadZipDialog = async () => {
    const selectedFiles = await dialog.showOpenDialog({
        properties: ["openFile", "multiSelections"],
        filters: [{ name: "Zip File", extensions: ["zip"] }],
    });
    const filePaths = selectedFiles.filePaths;

    let files: ElectronFile[] = [];

    for (const filePath of filePaths) {
        files = [...files, ...(await getElectronFilesFromGoogleZip(filePath))];
    }

    return {
        zipPaths: filePaths,
        files,
    };
};
