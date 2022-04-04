import { ElectronFile, FileWithCollection, Metadata } from 'types/upload';
import { EnteFile } from 'types/file';
import { convertToHumanReadable } from 'utils/billing';
import { formatDateTime } from 'utils/file';
import { getLogs, saveLogLine } from 'utils/storage';
import { A_SEC_IN_MICROSECONDS } from 'constants/upload';

const TYPE_JSON = 'json';
const DEDUPE_COLLECTION = new Set(['icloud library', 'icloudlibrary']);

export function fileAlreadyInCollection(
    existingFilesInCollection: EnteFile[],
    newFileMetadata: Metadata
): boolean {
    for (const existingFile of existingFilesInCollection) {
        if (areFilesSame(existingFile.metadata, newFileMetadata)) {
            return true;
        }
    }
    return false;
}

export function shouldDedupeAcrossCollection(collectionName: string): boolean {
    // using set to avoid unnecessary regex for removing spaces for each upload
    return DEDUPE_COLLECTION.has(collectionName.toLocaleLowerCase());
}

export function areFilesSame(
    existingFile: Metadata,
    newFile: Metadata
): boolean {
    if (
        existingFile.fileType === newFile.fileType &&
        Math.abs(existingFile.creationTime - newFile.creationTime) <
            A_SEC_IN_MICROSECONDS &&
        Math.abs(existingFile.modificationTime - newFile.modificationTime) <
            A_SEC_IN_MICROSECONDS &&
        existingFile.title === newFile.title
    ) {
        return true;
    } else {
        return false;
    }
}

export function segregateMetadataAndMediaFiles(
    filesWithCollectionToUpload: FileWithCollection[]
) {
    const metadataJSONFiles: FileWithCollection[] = [];
    const mediaFiles: FileWithCollection[] = [];
    filesWithCollectionToUpload.forEach((fileWithCollection) => {
        const file = fileWithCollection.file;
        if (file.name.startsWith('.')) {
            // ignore files with name starting with . (hidden files)
            return;
        }
        if (file.name.toLowerCase().endsWith(TYPE_JSON)) {
            metadataJSONFiles.push(fileWithCollection);
        } else {
            mediaFiles.push(fileWithCollection);
        }
    });
    return { mediaFiles, metadataJSONFiles };
}

export function logUploadInfo(log: string) {
    saveLogLine({
        type: 'upload',
        timestamp: Date.now(),
        logLine: log,
    });
}

export function getUploadLogs() {
    return getLogs()
        .filter((log) => log.type === 'upload')
        .map((log) => `[${formatDateTime(log.timestamp)}] ${log.logLine}`);
}

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertToHumanReadable(file.size)}`;
}

export function areSameElectronFiles(
    file: FileWithCollection,
    fileWithCollection: FileWithCollection
): boolean {
    return (
        (file.file as ElectronFile).path ===
        (fileWithCollection.file as ElectronFile).path
    );
}
