import { getZipFileStream } from './../services/fs';
import { getElectronFile, getValidPaths } from './../services/fs';
import path from 'path';
import StreamZip from 'node-stream-zip';
import { uploadStatusStore } from '../services/store';
import { ElectronFile, FILE_PATH_KEYS, FILE_PATH_TYPE } from '../types';
import { logError } from '../utils/logging';
import { ipcRenderer } from 'electron';

async function getZipEntryAsElectronFile(
    zip: StreamZip.StreamZipAsync,
    entry: StreamZip.ZipEntry
): Promise<ElectronFile> {
    return {
        path: entry.name,
        name: path.basename(entry.name),
        size: entry.size,
        lastModified: entry.time,
        stream: async () => {
            return await getZipFileStream(zip, entry.name);
        },
        blob: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Blob([new Uint8Array(buffer)]);
        },
        arrayBuffer: async () => {
            const buffer = await zip.entryData(entry.name);
            return new Uint8Array(buffer);
        },
    };
}

export const setToUploadFiles = (type: FILE_PATH_TYPE, filePaths: string[]) => {
    const key = FILE_PATH_KEYS[type];
    if (filePaths) {
        uploadStatusStore.set(key, filePaths);
    } else {
        uploadStatusStore.delete(key);
    }
};

export const setToUploadCollection = (collectionName: string) => {
    if (collectionName) {
        uploadStatusStore.set('collectionName', collectionName);
    } else {
        uploadStatusStore.delete('collectionName');
    }
};

export const getPendingUploads = async () => {
    const filePaths = getSavedPaths(FILE_PATH_TYPE.FILES);
    const zipPaths = getSavedPaths(FILE_PATH_TYPE.ZIPS);
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

export const getElectronFilesFromGoogleZip = async (filePath: string) => {
    const zip = new StreamZip.async({
        file: filePath,
    });

    const entries = await zip.entries();
    const files: ElectronFile[] = [];

    for (const entry of Object.values(entries)) {
        const basename = path.basename(entry.name);
        if (entry.isFile && basename.length > 0 && basename[0] !== '.') {
            files.push(await getZipEntryAsElectronFile(zip, entry));
        }
    }

    return files;
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

const getSavedPaths = (type: FILE_PATH_TYPE) => {
    const paths =
        getValidPaths(
            uploadStatusStore.get(FILE_PATH_KEYS[type]) as string[]
        ) ?? [];

    setToUploadFiles(type, paths);
    return paths;
};
