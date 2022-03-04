import { FileWithCollection, Metadata } from 'types/upload';
import { EnteFile } from 'types/file';
import { convertToHumanReadable } from 'utils/billing';

const TYPE_JSON = 'json';

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
export function areFilesSame(
    existingFile: Metadata,
    newFile: Metadata
): boolean {
    if (
        existingFile.fileType === newFile.fileType &&
        existingFile.creationTime === newFile.creationTime &&
        existingFile.modificationTime === newFile.modificationTime &&
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

export function getFileNameSize(file: File) {
    return `${file.name}_${convertToHumanReadable(file.size)}`;
}
