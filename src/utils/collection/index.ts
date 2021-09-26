import {
    addToCollection,
    Collection,
    CollectionType,
    createCollection,
    moveToCollection,
} from 'services/collectionService';
import { getSelectedFiles } from 'utils/file';
import { File } from 'services/fileService';
import { CustomError } from 'utils/common/errorUtil';
import { SelectedState } from 'pages/gallery';
import { User } from 'services/userService';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { COLLECTION_SORT_BY } from 'components/pages/gallery/CollectionSort';

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
}
export async function copyOrMoveFromCollection(
    type: COLLECTION_OPS_TYPE,
    setCollectionSelectorView: (value: boolean) => void,
    selected: SelectedState,
    files: File[],
    clearSelection: () => void,
    syncWithRemote: () => Promise<void>,
    setActiveCollection: (id: number) => void,
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
    switch (type) {
        case COLLECTION_OPS_TYPE.ADD:
            await addToCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.MOVE:
            await moveToCollection(
                selected.collectionID,
                collection,
                selectedFiles
            );
            break;
        default:
            throw Error(CustomError.INVALID_COLLECTION_OPERATION);
    }
    clearSelection();
    await syncWithRemote();
    setActiveCollection(collection.id);
}

export function getSelectedCollection(collectionID: number, collections) {
    return collections.find((collection) => collection.id === collectionID);
}

export function isSharedCollection(
    collections: Collection[],
    collectionID: number
) {
    const user: User = getData(LS_KEYS.USER);

    const collection = collections.find(
        (collection) => collection.id === collectionID
    );
    if (!collection) {
        return false;
    }
    return collection?.owner.id !== user.id;
}
export function sortCollections(
    collections: Collection[],
    sortBy: COLLECTION_SORT_BY
) {
    console.log(sortBy, collections[0]);
    return collections.sort((collection1, collection2) => {
        const a = collection1[sortBy];
        const b = collection2[sortBy];
        if (typeof a === 'string') return a.localeCompare(b);
        else {
            return b - a;
        }
    });
}
