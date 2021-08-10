import { Collection } from 'services/collectionService';
import { FileInMemory, MetadataObject } from 'services/upload/uploadService';

export function fileAlreadyInCollection(
    existingFilesCollectionWise,
    newFile: FileInMemory,
    collection: Collection,
): boolean {
    const collectionFiles =
        existingFilesCollectionWise.get(collection.id) ?? [];
    for (const existingFile of collectionFiles) {
        if (areFilesSame(existingFile.metadata, newFile.metadata)) {
            return true;
        }
    }
    return false;
}
export function areFilesSame(
    existingFile: MetadataObject,
    newFile: MetadataObject,
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
