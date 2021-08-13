import { FileWithCollection } from 'services/upload/uploadManager';
import { FileInMemory, MetadataObject } from 'services/upload/uploadService';
import { File } from 'services/fileService';
const TYPE_JSON = 'json';

export function fileAlreadyInCollection(
    existingFilesInCollection: File[],
    newFile: FileInMemory
): boolean {
    for (const existingFile of existingFilesInCollection) {
        if (areFilesSame(existingFile.metadata, newFile.metadata)) {
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
        if (file?.name.substr(0, 1) === '.') {
            // ignore files with name starting with . (hidden files)
            return;
        }
        if (file.name.slice(-4) === TYPE_JSON) {
            metadataFiles.push(fileWithCollection);
        } else {
            mediaFiles.push(fileWithCollection);
        }
    });
    return { mediaFiles, metadataFiles };
}
