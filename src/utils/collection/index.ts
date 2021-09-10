import {
    addToCollection,
    Collection,
    CollectionType,
    createCollection,
} from 'services/collectionService';
import { getSelectedFiles } from 'utils/file';
import { File } from 'services/fileService';

export async function addFilesToCollection(
    setCollectionSelectorView: (value: boolean) => void,
    selected: any,
    files: File[],
    clearSelection: () => void,
    syncWithRemote: () => Promise<void>,
    selectCollection: (id: number) => void,
    collectionName: string,
    existingCollection: Collection
) {
    setCollectionSelectorView(false);
    let collection: Collection;
    if (!existingCollection) {
        collection = await createCollection(
            collectionName,
            CollectionType.album
        );
    } else {
        collection = existingCollection;
    }
    const selectedFiles = getSelectedFiles(selected, files);
    await addToCollection(collection, selectedFiles);
    clearSelection();
    await syncWithRemote();
    selectCollection(collection.id);
}

export function getSelectedCollection(collectionID: number, collections) {
    return collections.find((collection) => collection.id === collectionID);
}
