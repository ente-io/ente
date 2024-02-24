import { ENTE_METADATA_FOLDER } from "constants/export";
import { FILE_TYPE } from "constants/file";
import {
    A_SEC_IN_MICROSECONDS,
    DEFAULT_IMPORT_SUGGESTION,
    PICKED_UPLOAD_TYPE,
} from "constants/upload";
import isElectron from "is-electron";
import { EnteFile } from "types/file";
import {
    ElectronFile,
    FileWithCollection,
    ImportSuggestion,
    Metadata,
} from "types/upload";

const TYPE_JSON = "json";
const DEDUPE_COLLECTION = new Set(["icloud library", "icloudlibrary"]);

export function findMatchingExistingFiles(
    existingFiles: EnteFile[],
    newFileMetadata: Metadata,
): EnteFile[] {
    const matchingFiles: EnteFile[] = [];
    for (const existingFile of existingFiles) {
        if (areFilesSame(existingFile.metadata, newFileMetadata)) {
            matchingFiles.push(existingFile);
        }
    }
    return matchingFiles;
}

export function shouldDedupeAcrossCollection(collectionName: string): boolean {
    // using set to avoid unnecessary regex for removing spaces for each upload
    return DEDUPE_COLLECTION.has(collectionName.toLocaleLowerCase());
}

export function areFilesSame(
    existingFile: Metadata,
    newFile: Metadata,
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
    newFile: Metadata,
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
    filesWithCollectionToUpload: FileWithCollection[],
) {
    const metadataJSONFiles: FileWithCollection[] = [];
    const mediaFiles: FileWithCollection[] = [];
    filesWithCollectionToUpload.forEach((fileWithCollection) => {
        const file = fileWithCollection.file;
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
    secondFile: FileWithCollection,
): boolean {
    return firstFile.localID === secondFile.localID;
}

export function getImportSuggestion(
    uploadType: PICKED_UPLOAD_TYPE,
    toUploadFiles: File[] | ElectronFile[],
): ImportSuggestion {
    if (isElectron() && uploadType === PICKED_UPLOAD_TYPE.FILES) {
        return DEFAULT_IMPORT_SUGGESTION;
    }

    const paths: string[] = toUploadFiles.map((file) => file["path"]);
    const getCharCount = (str: string) => (str.match(/\//g) ?? []).length;
    paths.sort((path1, path2) => getCharCount(path1) - getCharCount(path2));
    const firstPath = paths[0];
    const lastPath = paths[paths.length - 1];

    const L = firstPath.length;
    let i = 0;
    const firstFileFolder = firstPath.substring(0, firstPath.lastIndexOf("/"));
    const lastFileFolder = lastPath.substring(0, lastPath.lastIndexOf("/"));

    while (i < L && firstPath.charAt(i) === lastPath.charAt(i)) i++;
    let commonPathPrefix = firstPath.substring(0, i);

    if (commonPathPrefix) {
        commonPathPrefix = commonPathPrefix.substring(
            0,
            commonPathPrefix.lastIndexOf("/"),
        );
        if (commonPathPrefix) {
            commonPathPrefix = commonPathPrefix.substring(
                commonPathPrefix.lastIndexOf("/") + 1,
            );
        }
    }
    return {
        rootFolderName: commonPathPrefix || null,
        hasNestedFolders: firstFileFolder !== lastFileFolder,
        hasRootLevelFileWithFolder: firstFileFolder === "",
    };
}

// This function groups files that are that have the same parent folder into collections
// For Example, for user files have a directory structure like this
//              a
//            / |  \
//           b  j   c
//          /|\    /  \
//         e f g   h  i
//
// The files will grouped into 3 collections.
// [a => [j],
// b => [e,f,g],
// c => [h, i]]
export function groupFilesBasedOnParentFolder(
    toUploadFiles: File[] | ElectronFile[],
) {
    const collectionNameToFilesMap = new Map<string, (File | ElectronFile)[]>();
    for (const file of toUploadFiles) {
        const filePath = file["path"] as string;

        let folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
        // If the parent folder of a file is "metadata"
        // we consider it to be part of the parent folder
        // For Eg,For FileList  -> [a/x.png, a/metadata/x.png.json]
        // they will both we grouped into the collection "a"
        // This is cluster the metadata json files in the same collection as the file it is for
        if (folderPath.endsWith(ENTE_METADATA_FOLDER)) {
            folderPath = folderPath.substring(0, folderPath.lastIndexOf("/"));
        }
        const folderName = folderPath.substring(
            folderPath.lastIndexOf("/") + 1,
        );
        if (!folderName?.length) {
            throw Error("folderName can't be null");
        }
        if (!collectionNameToFilesMap.has(folderName)) {
            collectionNameToFilesMap.set(folderName, []);
        }
        collectionNameToFilesMap.get(folderName).push(file);
    }
    return collectionNameToFilesMap;
}

export function filterOutSystemFiles(files: File[] | ElectronFile[]) {
    if (files[0] instanceof File) {
        const browserFiles = files as File[];
        return browserFiles.filter((file) => {
            return !isSystemFile(file);
        });
    } else {
        const electronFiles = files as ElectronFile[];
        return electronFiles.filter((file) => {
            return !isSystemFile(file);
        });
    }
}

export function isSystemFile(file: File | ElectronFile) {
    return file.name.startsWith(".");
}
