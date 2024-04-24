import { basename, dirname } from "@/next/file";
import { ElectronFile } from "@/next/types/file";
import { PICKED_UPLOAD_TYPE } from "constants/upload";
import isElectron from "is-electron";
import { exportMetadataDirectoryName } from "services/export";
import {
    FileWithCollection,
    Metadata,
    type FileWithCollection2,
} from "types/upload";

const TYPE_JSON = "json";

export const hasFileHash = (file: Metadata) =>
    file.hash || (file.imageHash && file.videoHash);

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
    firstFile: FileWithCollection2,
    secondFile: FileWithCollection2,
): boolean {
    return firstFile.localID === secondFile.localID;
}

/**
 * Return true if all the paths in the given list are items that belong to the
 * same (arbitrary) directory.
 *
 * Empty list of paths is considered to be in the same directory.
 */
export const areAllInSameDirectory = (paths: string[]) =>
    new Set(paths.map(dirname)).size == 1;

// This is used to prompt the user the make upload strategy choice
export interface ImportSuggestion {
    rootFolderName: string;
    hasNestedFolders: boolean;
    hasRootLevelFileWithFolder: boolean;
}

export const DEFAULT_IMPORT_SUGGESTION: ImportSuggestion = {
    rootFolderName: "",
    hasNestedFolders: false,
    hasRootLevelFileWithFolder: false,
};

export function getImportSuggestion(
    uploadType: PICKED_UPLOAD_TYPE,
    paths: string[],
): ImportSuggestion {
    if (isElectron() && uploadType === PICKED_UPLOAD_TYPE.FILES) {
        return DEFAULT_IMPORT_SUGGESTION;
    }

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
    toUploadFiles: File[] | ElectronFile[] | string[],
) {
    const collectionNameToFilesMap = new Map<
        string,
        File[] | ElectronFile[] | string[]
    >();
    for (const file of toUploadFiles) {
        const filePath =
            typeof file == "string" ? file : (file["path"] as string);

        let folderPath = filePath.substring(0, filePath.lastIndexOf("/"));
        // If the parent folder of a file is "metadata"
        // we consider it to be part of the parent folder
        // For Eg,For FileList  -> [a/x.png, a/metadata/x.png.json]
        // they will both we grouped into the collection "a"
        // This is cluster the metadata json files in the same collection as the file it is for
        if (folderPath.endsWith(exportMetadataDirectoryName)) {
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
        // TODO: Remove the cast
        collectionNameToFilesMap.get(folderName).push(file as any);
    }
    return collectionNameToFilesMap;
}

export function filterOutSystemFiles(
    files: File[] | ElectronFile[] | string[] | undefined | null,
) {
    if (!files) return files;

    if (files[0] instanceof File) {
        const browserFiles = files as File[];
        return browserFiles.filter((file) => {
            return !isSystemFile(file);
        });
    } else if (typeof files[0] == "string") {
        const filePaths = files as string[];
        return filePaths.filter((path) => !isHiddenFile(path));
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

/**
 * Return true if the file at the given {@link path} is hidden.
 *
 * Hidden files are those whose names begin with a "." (dot).
 */
export const isHiddenFile = (path: string) => basename(path).startsWith(".");
