import { getElectronFile } from "../services/fs";
import {
    getElectronFilesFromGoogleZip,
    getSavedFilePaths,
} from "../services/upload";
import { uploadStatusStore } from "../stores/upload.store";
import { ElectronFile, FILE_PATH_TYPE } from "../types/ipc";

export const getPendingUploads = async () => {
    const filePaths = getSavedFilePaths(FILE_PATH_TYPE.FILES);
    const zipPaths = getSavedFilePaths(FILE_PATH_TYPE.ZIPS);
    const collectionName = uploadStatusStore.get("collectionName");

    let files: ElectronFile[] = [];
    let type: FILE_PATH_TYPE;
    if (zipPaths.length) {
        type = FILE_PATH_TYPE.ZIPS;
        for (const zipPath of zipPaths) {
            files = [
                ...files,
                ...(await getElectronFilesFromGoogleZip(zipPath)),
            ];
        }
        const pendingFilePaths = new Set(filePaths);
        files = files.filter((file) => pendingFilePaths.has(file.path));
    } else if (filePaths.length) {
        type = FILE_PATH_TYPE.FILES;
        files = await Promise.all(filePaths.map(getElectronFile));
    }
    return {
        files,
        collectionName,
        type,
    };
};

export {
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
    setToUploadFiles,
} from "../services/upload";
