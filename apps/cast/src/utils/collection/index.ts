import {
    getNonEmptyCollections,
    updatePublicCollectionMagicMetadata,
} from 'services/collectionService';
import { EnteFile } from 'types/file';
import { logError } from '@ente/shared/sentry';
import {
    COLLECTION_ROLE,
    Collection,
    CollectionPublicMagicMetadataProps,
} from 'types/collection';
import {
    CollectionSummaryType,
    CollectionType,
    HIDE_FROM_COLLECTION_BAR_TYPES,
    OPTIONS_NOT_HAVING_COLLECTION_TYPES,
} from 'constants/collection';
import { SUB_TYPE, VISIBILITY_STATE } from 'types/magicMetadata';
import { updateMagicMetadata } from 'utils/magicMetadata';
import { User } from '@ente/shared/user/types';
import { getData, LS_KEYS } from '@ente/shared/storage/localStorage';

export enum COLLECTION_OPS_TYPE {
    ADD,
    MOVE,
    REMOVE,
    RESTORE,
    UNHIDE,
}

export function getSelectedCollection(
    collectionID: number,
    collections: Collection[]
) {
    return collections.find((collection) => collection.id === collectionID);
}

export const changeCollectionSortOrder = async (
    collection: Collection,
    asc: boolean
) => {
    try {
        const updatedPublicMagicMetadataProps: CollectionPublicMagicMetadataProps =
            {
                asc,
            };

        const updatedPubMagicMetadata = await updateMagicMetadata(
            updatedPublicMagicMetadataProps,
            collection.pubMagicMetadata,
            collection.key
        );

        await updatePublicCollectionMagicMetadata(
            collection,
            updatedPubMagicMetadata
        );
    } catch (e) {
        logError(e, 'change collection sort order failed');
    }
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
        type === CollectionSummaryType.hiddenItems ||
        type === CollectionSummaryType.incomingShareViewer ||
        type === CollectionSummaryType.incomingShareCollaborator ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived ||
        type === CollectionSummaryType.pinned
    );
};
export const showShareQuickOption = (type: CollectionSummaryType) => {
    return (
        type === CollectionSummaryType.folder ||
        type === CollectionSummaryType.album ||
        type === CollectionSummaryType.outgoingShare ||
        type === CollectionSummaryType.sharedOnlyViaLink ||
        type === CollectionSummaryType.archived ||
        type === CollectionSummaryType.incomingShareViewer ||
        type === CollectionSummaryType.incomingShareCollaborator ||
        type === CollectionSummaryType.pinned
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
    collection.magicMetadata?.data.visibility === VISIBILITY_STATE.HIDDEN;

export const isQuickLinkCollection = (collection: Collection) =>
    collection.magicMetadata?.data.subType === SUB_TYPE.QUICK_LINK_COLLECTION;

export function isOutgoingShare(collection: Collection, user: User): boolean {
    return collection.owner.id === user.id && collection.sharees?.length > 0;
}

export function isIncomingShare(collection: Collection, user: User) {
    return collection.owner.id !== user.id;
}

export function isIncomingViewerShare(collection: Collection, user: User) {
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role === COLLECTION_ROLE.VIEWER;
}

export function isIncomingCollabShare(collection: Collection, user: User) {
    const sharee = collection.sharees?.find((sharee) => sharee.id === user.id);
    return sharee?.role === COLLECTION_ROLE.COLLABORATOR;
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

export function getHiddenCollections(collections: Collection[]): Collection[] {
    return collections.filter((collection) => isHiddenCollection(collection));
}
