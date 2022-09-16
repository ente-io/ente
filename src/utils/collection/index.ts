import {
    addToCollection,
    moveToCollection,
    removeFromCollection,
    restoreToCollection,
    updateCollectionMagicMetadata,
} from 'services/collectionService';
import { downloadFiles } from 'utils/file';
import { getLocalFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { CustomError, ServerErrorCodes } from 'utils/error';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { logError } from 'utils/sentry';
import constants from 'utils/strings/constants';
import {
    Collection,
    CollectionMagicMetadataProps,
    CollectionSummaries,
} from 'types/collection';
import {
    CollectionSummaryType,
    CollectionType,
    HIDE_FROM_COLLECTION_BAR_TYPES,
    OPTIONS_NOT_HAVING_COLLECTION_TYPES,
    SYSTEM_COLLECTION_TYPES,
    UPLOAD_NOT_ALLOWED_COLLECTION_TYPES,
} from 'constants/collection';
import { getAlbumSiteHost } from 'constants/pages';
import { getUnixTimeInMicroSecondsWithDelta } from 'utils/time';
import {
    NEW_COLLECTION_MAGIC_METADATA,
    VISIBILITY_STATE,
} from 'types/magicMetadata';
import { IsArchived, updateMagicMetadataProps } from 'utils/magicMetadata';

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
    REMOVE,
    RESTORE,
}
export async function handleCollectionOps(
    type: COLLECTION_OPS_TYPE,
    collection: Collection,
    selectedFiles: EnteFile[],
    selectedCollectionID: number
) {
    switch (type) {
        case COLLECTION_OPS_TYPE.ADD:
            await addToCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.MOVE:
            await moveToCollection(
                collection,
                selectedCollectionID,
                selectedFiles
            );
            break;
        case COLLECTION_OPS_TYPE.REMOVE:
            await removeFromCollection(collection.id, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.RESTORE:
            await restoreToCollection(collection, selectedFiles);
            break;
        default:
            throw Error(CustomError.INVALID_COLLECTION_OPERATION);
    }
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

export async function downloadAllCollectionFiles(collectionID: number) {
    try {
        const allFiles = await getLocalFiles();
        const collectionFiles = allFiles.filter(
            (file) => file.collectionID === collectionID
        );
        await downloadFiles(collectionFiles);
    } catch (e) {
        logError(e, 'download collection failed ');
    }
}

export function appendCollectionKeyToShareURL(
    url: string,
    collectionKey: string
) {
    if (!url) {
        return null;
    }
    const bs58 = require('bs58');
    const sharableURL = new URL(url);
    if (process.env.NODE_ENV === 'development') {
        sharableURL.host = getAlbumSiteHost();
        sharableURL.protocol = 'http';
    }
    const bytes = Buffer.from(collectionKey, 'base64');
    sharableURL.hash = bs58.encode(bytes);
    return sharableURL.href;
}

const _intSelectOption = (i: number) => {
    return { label: i.toString(), value: i };
};

export function getDeviceLimitOptions() {
    return [2, 5, 10, 25, 50].map((i) => _intSelectOption(i));
}

export const shareExpiryOptions = [
    { label: 'never', value: () => 0 },
    {
        label: 'after 1 hour',
        value: () => getUnixTimeInMicroSecondsWithDelta({ hours: 1 }),
    },
    {
        label: 'after 1 day',
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 1 }),
    },
    {
        label: 'after 1 week',
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 7 }),
    },
    {
        label: 'after 1 month',
        value: () => getUnixTimeInMicroSecondsWithDelta({ months: 1 }),
    },
    {
        label: 'after 1 year',
        value: () => getUnixTimeInMicroSecondsWithDelta({ years: 1 }),
    },
];

export const changeCollectionVisibility = async (
    collection: Collection,
    visibility: VISIBILITY_STATE
) => {
    try {
        const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
            visibility,
        };

        const updatedCollection = {
            ...collection,
            magicMetadata: await updateMagicMetadataProps(
                collection.magicMetadata ?? NEW_COLLECTION_MAGIC_METADATA,
                collection.key,
                updatedMagicMetadataProps
            ),
        } as Collection;

        await updateCollectionMagicMetadata(updatedCollection);
    } catch (e) {
        logError(e, 'change file visibility failed');
        switch (e.status?.toString()) {
            case ServerErrorCodes.FORBIDDEN:
                throw Error(constants.NOT_FILE_OWNER);
        }
        throw e;
    }
};

export const getArchivedCollections = (collections: Collection[]) => {
    return new Set<number>(
        collections.filter(IsArchived).map((collection) => collection.id)
    );
};

export const hasNonSystemCollections = (
    collectionSummaries: CollectionSummaries
) => {
    return collectionSummaries?.size > 3;
};

export const isUploadAllowedCollection = (type: CollectionSummaryType) => {
    return !UPLOAD_NOT_ALLOWED_COLLECTION_TYPES.has(type);
};

export const isSystemCollection = (type: CollectionSummaryType) => {
    return SYSTEM_COLLECTION_TYPES.has(type);
};

export const shouldShowOptions = (type: CollectionSummaryType) => {
    return !OPTIONS_NOT_HAVING_COLLECTION_TYPES.has(type);
};

export const shouldBeShownOnCollectionBar = (type: CollectionSummaryType) => {
    return !HIDE_FROM_COLLECTION_BAR_TYPES.has(type);
};

export const getUserOwnedCollections = (collections: Collection[]) => {
    const user: User = getData(LS_KEYS.USER);
    if (!user?.id) {
        throw Error('user missing');
    }
    return collections.filter((collection) => collection.owner.id === user.id);
};
