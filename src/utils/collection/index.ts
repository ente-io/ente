import {
    addToCollection,
    moveToCollection,
    removeFromCollection,
    restoreToCollection,
} from 'services/collectionService';
import { downloadFiles, getSelectedFiles } from 'utils/file';
import { getLocalFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { CustomError } from 'utils/error';
import { SelectedState } from 'types/gallery';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { SetDialogMessage } from 'components/MessageDialog';
import { logError } from 'utils/sentry';
import constants from 'utils/strings/constants';
import { Collection } from 'types/collection';
import { CollectionType } from 'constants/collection';
import CryptoWorker from 'utils/crypto';

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
    REMOVE,
    RESTORE,
}
export async function handleCollectionOps(
    type: COLLECTION_OPS_TYPE,
    setCollectionSelectorView: (value: boolean) => void,
    selected: SelectedState,
    files: EnteFile[],
    setActiveCollection: (id: number) => void,
    collection: Collection
) {
    setCollectionSelectorView(false);
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
        case COLLECTION_OPS_TYPE.REMOVE:
            await removeFromCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.RESTORE:
            await restoreToCollection(collection, selectedFiles);
            break;
        default:
            throw Error(CustomError.INVALID_COLLECTION_OPERATION);
    }
    setActiveCollection(collection.id);
}

export function getSelectedCollection(
    collectionID: number,
    collections: Collection[]
) {
    return collections.find((collection) => collection.id === collectionID);
}

export function isSharedCollection(
    collectionID: number,
    collections: Collection[]
) {
    const user: User = getData(LS_KEYS.USER);

    const collection = getSelectedCollection(collectionID, collections);
    if (!collection) {
        return false;
    }
    return collection?.owner.id !== user.id;
}

export function isFavoriteCollection(
    collectionID: number,
    collections: Collection[]
) {
    const collection = getSelectedCollection(collectionID, collections);
    if (!collection) {
        return false;
    } else {
        return collection.type === CollectionType.favorites;
    }
}

export async function downloadCollection(
    collectionID: number,
    setDialogMessage: SetDialogMessage
) {
    try {
        const allFiles = await getLocalFiles();
        const collectionFiles = allFiles.filter(
            (file) => file.collectionID === collectionID
        );
        await downloadFiles(collectionFiles);
    } catch (e) {
        logError(e, 'download collection failed ');
        setDialogMessage({
            title: constants.ERROR,
            content: constants.DELETE_COLLECTION_FAILED,
            close: { variant: 'danger' },
        });
    }
}

export async function transformShareURLForHost(
    url: string,
    collectionKey: string
) {
    const worker = await new CryptoWorker();
    if (!url) {
        return null;
    }
    const host = window.location.host;
    const sharableURL = new URL(url);
    sharableURL.host = host;
    sharableURL.pathname = '/shared-album';
    sharableURL.hash = await worker.toHex(collectionKey);
    sharableURL.protocol = 'http';
    return sharableURL.href;
}
