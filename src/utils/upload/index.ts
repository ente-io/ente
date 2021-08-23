import { FileWithCollection } from 'services/upload/uploadManager';
import { MetadataObject } from 'services/upload/uploadService';
import { File } from 'services/fileService';
const TYPE_JSON = 'json';

export function fileAlreadyInCollection(
    existingFilesInCollection: File[],
    newFileMetadata: MetadataObject
): boolean {
    for (const existingFile of existingFilesInCollection) {
        if (areFilesSame(existingFile.metadata, newFileMetadata)) {
            return true;
        }
    }
    return false;
}
export function areFilesSame(
    existingFile: MetadataObject,
    newFile: MetadataObject
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

export function segregateFiles(
    filesWithCollectionToUpload: FileWithCollection[]
) {
    const metadataFiles: FileWithCollection[] = [];
    const mediaFiles: FileWithCollection[] = [];
    filesWithCollectionToUpload.forEach((fileWithCollection) => {
        const file = fileWithCollection.file;
        if (file.name.startsWith('.')) {
            // ignore files with name starting with . (hidden files)
            return;
        }
        if (file.name.toLowerCase().endsWith(TYPE_JSON)) {
            metadataFiles.push(fileWithCollection);
        } else {
            mediaFiles.push(fileWithCollection);
        }
    });
    return { mediaFiles, metadataFiles };
}
