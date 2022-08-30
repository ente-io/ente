import {
    AnalysisResult,
    ElectronFile,
    FileWithCollection,
    Metadata,
} from 'types/upload';
import { EnteFile } from 'types/file';
import {
    A_SEC_IN_MICROSECONDS,
    NULL_ANALYSIS_RESULT,
    UPLOAD_TYPE,
} from 'constants/upload';
import { FILE_TYPE } from 'constants/file';
import { METADATA_FOLDER_NAME } from 'constants/export';
import isElectron from 'is-electron';

const TYPE_JSON = 'json';
const DEDUPE_COLLECTION = new Set(['icloud library', 'icloudlibrary']);

export function findMatchingExistingFile(
    existingFiles: EnteFile[],
    newFileMetadata: Metadata
): EnteFile {
    for (const existingFile of existingFiles) {
        if (areFilesSame(existingFile.metadata, newFileMetadata)) {
            return existingFile;
        }
    }
    return null;
}

export function findSameFileInOtherCollection(
    existingFiles: EnteFile[],
    newFileMetadata: Metadata
) {
    if (!hasFileHash(newFileMetadata)) {
        return null;
    }

    for (const existingFile of existingFiles) {
        if (
            hasFileHash(existingFile.metadata) &&
            areFilesWithFileHashSame(existingFile.metadata, newFileMetadata)
        ) {
            return existingFile;
        }
    }
    return null;
}

export function shouldDedupeAcrossCollection(collectionName: string): boolean {
    // using set to avoid unnecessary regex for removing spaces for each upload
    return DEDUPE_COLLECTION.has(collectionName.toLocaleLowerCase());
}

export function areFilesSame(
    existingFile: Metadata,
    newFile: Metadata
): boolean {
    if (hasFileHash(existingFile) && hasFileHash(newFile)) {
        return areFilesWithFileHashSame(existingFile, newFile);
    } else {
        /*
         * The maximum difference in the creation/modification times of two similar files is set to 1 second.
         * This is because while uploading files in the web - browsers and users could have set reduced
         * precision of file times to prevent timing attacks and fingerprinting.
         * Context: https://developer.mozilla.org/en-US/docs/Web/API/File/lastModified#reduced_time_precision
         */
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
}

export function hasFileHash(file: Metadata) {
    return file.hash || (file.imageHash && file.videoHash);
}

export function areFilesWithFileHashSame(
    existingFile: Metadata,
    newFile: Metadata
): boolean {
    if (
        existingFile.fileType !== newFile.fileType ||
        existingFile.title !== newFile.title
    ) {
        return false;
    }
    if (existingFile.fileType === FILE_TYPE.LIVE_PHOTO) {
        return (
            existingFile.imageHash === newFile.imageHash &&
            existingFile.videoHash === newFile.videoHash
        );
    } else {
        return existingFile.hash === newFile.hash;
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

export function areFileWithCollectionsSame(
    firstFile: FileWithCollection,
    secondFile: FileWithCollection
): boolean {
    return firstFile.localID === secondFile.localID;
}

export function analyseUploadFiles(
    uploadType: UPLOAD_TYPE,
    toUploadFiles: File[] | ElectronFile[]
): AnalysisResult {
    if (isElectron() && uploadType === UPLOAD_TYPE.FILES) {
        return NULL_ANALYSIS_RESULT;
    }

    const paths: string[] = toUploadFiles.map((file) => file['path']);
    const getCharCount = (str: string) => (str.match(/\//g) ?? []).length;
    paths.sort((path1, path2) => getCharCount(path1) - getCharCount(path2));
    const firstPath = paths[0];
    const lastPath = paths[paths.length - 1];

    const L = firstPath.length;
    let i = 0;
    const firstFileFolder = firstPath.substring(0, firstPath.lastIndexOf('/'));
    const lastFileFolder = lastPath.substring(0, lastPath.lastIndexOf('/'));
    while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
    let commonPathPrefix = firstPath.substring(0, i);

    if (commonPathPrefix) {
        commonPathPrefix = commonPathPrefix.substring(
            0,
            commonPathPrefix.lastIndexOf('/')
        );
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substring(
                commonPathPrefix.lastIndexOf('/') + 1
            );
        }
    }
    return {
        suggestedCollectionName: commonPathPrefix || null,
        multipleFolders: firstFileFolder !== lastFileFolder,
    };
}
export function getCollectionWiseFiles(toUploadFiles: File[] | ElectronFile[]) {
    const collectionWiseFiles = new Map<string, (File | ElectronFile)[]>();
    for (const file of toUploadFiles) {
        const filePath = file['path'] as string;

        let folderPath = filePath.substring(0, filePath.lastIndexOf('/'));
        if (folderPath.endsWith(METADATA_FOLDER_NAME)) {
            folderPath = folderPath.substring(0, folderPath.lastIndexOf('/'));
        }
        const folderName = folderPath.substring(
            folderPath.lastIndexOf('/') + 1
        );
        if (!collectionWiseFiles.has(folderName)) {
            collectionWiseFiles.set(folderName, []);
        }
        collectionWiseFiles.get(folderName).push(file);
    }
    return collectionWiseFiles;
}
