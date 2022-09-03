import { getElectronFile } from './../services/fs';
import { uploadStatusStore } from '../stores/upload.store';
import { ElectronFile, FILE_PATH_TYPE } from '../types';
import { logError } from '../utils/logging';
import { ipcRenderer } from 'electron';
import {
    getElectronFilesFromGoogleZip,
    getSavedFilePaths,
} from '../services/upload';

export const getPendingUploads = async () => {
    const filePaths = getSavedFilePaths(FILE_PATH_TYPE.FILES);
    const zipPaths = getSavedFilePaths(FILE_PATH_TYPE.ZIPS);
    const collectionName = uploadStatusStore.get('collectionName');

    let files: ElectronFile[] = [];
    let type: FILE_PATH_TYPE;
    if (zipPaths.length) {
        type = FILE_PATH_TYPE.ZIPS;
        for (const zipPath of zipPaths) {
            files.push(...(await getElectronFilesFromGoogleZip(zipPath)));
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

export const showUploadDirsDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-dirs-dialog'
        );
        const files = await Promise.all(filePaths.map(getElectronFile));
        return files;
    } catch (e) {
        logError(e, 'error while selecting folders');
    }
};

export const showUploadFilesDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-files-dialog'
        );
        const files = await Promise.all(filePaths.map(getElectronFile));
        return files;
    } catch (e) {
        logError(e, 'error while selecting files');
    }
};

export const showUploadZipDialog = async () => {
    try {
        const filePaths: string[] = await ipcRenderer.invoke(
            'show-upload-zip-dialog'
        );
        const files: ElectronFile[] = [];

        for (const filePath of filePaths) {
            files.push(...(await getElectronFilesFromGoogleZip(filePath)));
        }

        return {
            zipPaths: filePaths,
            files,
        };
    } catch (e) {
        logError(e, 'error while selecting zips');
    }
};

export {
    setToUploadFiles,
    getElectronFilesFromGoogleZip,
    setToUploadCollection,
} from '../services/upload';
