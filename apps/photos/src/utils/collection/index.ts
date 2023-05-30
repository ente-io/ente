import {
    addToCollection,
    getNonEmptyCollections,
    moveToCollection,
    removeFromCollection,
    restoreToCollection,
    unhideToCollection,
    updateCollectionMagicMetadata,
} from 'services/collectionService';
import { downloadFiles } from 'utils/file';
import { getLocalFiles, getLocalHiddenFiles } from 'services/fileService';
import { EnteFile } from 'types/file';
import { CustomError, ServerErrorCodes } from 'utils/error';
import { User } from 'types/user';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import { logError } from 'utils/sentry';
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
import { getUnixTimeInMicroSecondsWithDelta } from 'utils/time';
import {
    NEW_COLLECTION_MAGIC_METADATA,
    SUB_TYPE,
    VISIBILITY_STATE,
} from 'types/magicMetadata';
import { IsArchived, updateMagicMetadata } from 'utils/magicMetadata';
import { getAlbumsURL } from 'utils/common/apiUtil';
import bs58 from 'bs58';
import { t } from 'i18next';

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
    REMOVE,
    RESTORE,
    UNHIDE,
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
                selectedCollectionID,
                collection,
                selectedFiles
            );
            break;
        case COLLECTION_OPS_TYPE.REMOVE:
            await removeFromCollection(collection.id, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.RESTORE:
            await restoreToCollection(collection, selectedFiles);
            break;
        case COLLECTION_OPS_TYPE.UNHIDE:
            await unhideToCollection(collection, selectedFiles);
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

export async function downloadHiddenFiles() {
    try {
        const hiddenFiles = await getLocalHiddenFiles();
        await downloadFiles(hiddenFiles);
    } catch (e) {
        logError(e, 'download hidden files failed ');
    }
}

export function appendCollectionKeyToShareURL(
    url: string,
    collectionKey: string
) {
    if (!url) {
        return null;
    }

    const sharableURL = new URL(url);
    const albumsURL = new URL(getAlbumsURL());

    sharableURL.protocol = albumsURL.protocol;
    sharableURL.host = albumsURL.host;
    sharableURL.pathname = albumsURL.pathname;

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

export const shareExpiryOptions = () => [
    { label: t('NEVER'), value: () => 0 },
    {
        label: t('AFTER_TIME.HOUR'),
        value: () => getUnixTimeInMicroSecondsWithDelta({ hours: 1 }),
    },
    {
        label: t('AFTER_TIME.DAY'),
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 1 }),
    },
    {
        label: t('AFTER_TIME.WEEK'),
        value: () => getUnixTimeInMicroSecondsWithDelta({ days: 7 }),
    },
    {
        label: t('AFTER_TIME.MONTH'),
        value: () => getUnixTimeInMicroSecondsWithDelta({ months: 1 }),
    },
    {
        label: t('AFTER_TIME.YEAR'),
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

        const updatedMagicMetadata = await updateMagicMetadata(
            collection.magicMetadata ?? NEW_COLLECTION_MAGIC_METADATA,
            collection.key,
            updatedMagicMetadataProps
        );
        await updateCollectionMagicMetadata(collection, updatedMagicMetadata);
    } catch (e) {
        logError(e, 'change file visibility failed');
        switch (e.status?.toString()) {
            case ServerErrorCodes.FORBIDDEN:
                throw Error(CustomError.NOT_FILE_OWNER);
        }
        throw e;
    }
};

export const changeCollectionSubType = async (
    collection: Collection,
    subType: SUB_TYPE
) => {
    const updatedMagicMetadataProps: CollectionMagicMetadataProps = {
        subType: subType,
    };

    const updatedMagicMetadata = await updateMagicMetadata(
        collection.magicMetadata ?? NEW_COLLECTION_MAGIC_METADATA,
        collection.key,
        updatedMagicMetadataProps
    );
    await updateCollectionMagicMetadata(collection, updatedMagicMetadata);
};

export const getArchivedCollections = (collections: Collection[]) => {
    return new Set<number>(
        collections.filter(IsArchived).map((collection) => collection.id)
    );
};

export const hasNonSystemCollections = (
    collectionSummaries: CollectionSummaries
) => {
    for (const collectionSummary of collectionSummaries.values()) {
        if (!isSystemCollection(collectionSummary.type)) return true;
    }
    return false;
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
export const showEmptyTrashQuickOption = (type: CollectionSummaryType) => {
    return type === CollectionSummaryType.trash;
};
export const showDownloadQuickOption = (type: CollectionSummaryType) => {
    return (
        type === CollectionSummaryType.folder ||
        type === CollectionSummaryType.favorites ||
        type === CollectionSummaryType.album ||
        type === CollectionSummaryType.uncategorized ||
        type === CollectionSummaryType.hidden ||
        type === CollectionSummaryType.incomingShare ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived
    );
};
export const showShareQuickOption = (type: CollectionSummaryType) => {
    return (
        type === CollectionSummaryType.folder ||
        type === CollectionSummaryType.album ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived
    );
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

export const isDefaultHiddenCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType === SUB_TYPE.DEFAULT_HIDDEN;

export const isHiddenCollection = (collection: Collection) =>
    collection.magicMetadata?.data.visibility === VISIBILITY_STATE.HIDDEN ||
    collection.magicMetadata?.data.subType === SUB_TYPE.DEFAULT_HIDDEN;

export const isQuickLinkCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType === SUB_TYPE.QUICK_LINK_COLLECTION;

export function isOutgoingShare(collection: Collection): boolean {
    return collection.sharees?.length > 0;
}
export function isIncomingShare(collection: Collection, user: User) {
    return collection.owner.id !== user.id;
}
export function isSharedOnlyViaLink(collection: Collection) {
    return collection.publicURLs?.length && !collection.sharees?.length;
}

export function isValidMoveTarget(
    sourceCollectionID: number,
    targetCollection: Collection,
    user: User
) {
    return (
        sourceCollectionID !== targetCollection.id &&
        !isHiddenCollection(targetCollection) &&
        !isQuickLinkCollection(targetCollection) &&
        !isIncomingShare(targetCollection, user)
    );
}

export function isValidReplacementAlbum(
    collection: Collection,
    user: User,
    wantedCollectionName: string
) {
    return (
        collection.name === wantedCollectionName &&
        (collection.type === CollectionType.album ||
            collection.type === CollectionType.folder) &&
        !isHiddenCollection(collection) &&
        !isQuickLinkCollection(collection) &&
        !isIncomingShare(collection, user)
    );
}

export function getCollectionNameMap(
    collections: Collection[]
): Map<number, string> {
    return new Map<number, string>(
        collections.map((collection) => [collection.id, collection.name])
    );
}

export function getNonEmptyPersonalCollections(
    collections: Collection[],
    personalFiles: EnteFile[],
    user: User
): Collection[] {
    if (!user?.id) {
        throw Error('user missing');
    }
    const nonEmptyCollections = getNonEmptyCollections(
        collections,
        personalFiles
    );
    const personalCollections = nonEmptyCollections.filter(
        (collection) => collection.owner.id === user?.id
    );
    return personalCollections;
}

export function getNonHiddenCollections(
    collections: Collection[]
): Collection[] {
    return collections.filter((collection) => !isHiddenCollection(collection));
}

export async function splitNormalAndHiddenCollections(
    collections: Collection[]
): Promise<{
    normalCollections: Collection[];
    hiddenCollections: Collection[];
}> {
    const normalCollections = [];
    const hiddenCollections = [];
    for (const collection of collections) {
        if (isHiddenCollection(collection)) {
            hiddenCollections.push(collection);
        } else {
            normalCollections.push(collection);
        }
    }
    return { normalCollections, hiddenCollections };
}

export function constructCollectionNameMap(
    collections: Collection[]
): Map<number, string> {
    return new Map<number, string>(
        (collections ?? []).map((collection) => [
            collection.id,
            collection.name,
        ])
    );
}
