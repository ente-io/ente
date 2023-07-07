export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_SECTION = -3;
export const HIDDEN_SECTION = -4;
export const ALL_SECTION = 0;
export enum CollectionType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
    uncategorized = 'uncategorized',
}

export enum CollectionSummaryType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
    archive = 'archive',
    trash = 'trash',
    uncategorized = 'uncategorized',
    all = 'all',
    outgoingShare = 'outgoingShare',
    incomingShareViewer = 'incomingShareViewer',
    incomingShareCollaborator = 'incomingShareCollaborator',
    sharedOnlyViaLink = 'sharedOnlyViaLink',
    archived = 'archived',
    hidden = 'hidden',
}
export enum COLLECTION_LIST_SORT_BY {
    NAME,
    CREATION_TIME_ASCENDING,
    UPDATION_TIME_DESCENDING,
}

export const COLLECTION_SHARE_DEFAULT_VALID_DURATION =
    10 * 24 * 60 * 60 * 1000 * 1000;
export const COLLECTION_SHARE_DEFAULT_DEVICE_LIMIT = 4;

export const COLLECTION_SORT_ORDER = new Map([
    [CollectionSummaryType.all, 0],
    [CollectionSummaryType.uncategorized, 1],
    [CollectionSummaryType.favorites, 2],
    [CollectionSummaryType.album, 3],
    [CollectionSummaryType.folder, 3],
    [CollectionSummaryType.incomingShareViewer, 3],
    [CollectionSummaryType.incomingShareCollaborator, 3],
    [CollectionSummaryType.outgoingShare, 3],
    [CollectionSummaryType.sharedOnlyViaLink, 3],
    [CollectionSummaryType.archived, 3],
    [CollectionSummaryType.archive, 4],
    [CollectionSummaryType.trash, 5],
    [CollectionSummaryType.hidden, 5],
]);

export const SYSTEM_COLLECTION_TYPES = new Set([
    CollectionSummaryType.all,
    CollectionSummaryType.archive,
    CollectionSummaryType.trash,
    CollectionSummaryType.uncategorized,
    CollectionSummaryType.hidden,
]);

export const ADD_TO_NOT_ALLOWED_COLLECTION = new Set([
    CollectionSummaryType.all,
    CollectionSummaryType.archive,
    CollectionSummaryType.incomingShareViewer,
    CollectionSummaryType.trash,
    CollectionSummaryType.uncategorized,
    CollectionSummaryType.hidden,
]);

export const MOVE_TO_NOT_ALLOWED_COLLECTION = new Set([
    CollectionSummaryType.all,
    CollectionSummaryType.archive,
    CollectionSummaryType.incomingShareViewer,
    CollectionSummaryType.incomingShareCollaborator,
    CollectionSummaryType.trash,
    CollectionSummaryType.uncategorized,
    CollectionSummaryType.hidden,
]);

export const OPTIONS_NOT_HAVING_COLLECTION_TYPES = new Set([
    CollectionSummaryType.all,
    CollectionSummaryType.archive,
]);

export const HIDE_FROM_COLLECTION_BAR_TYPES = new Set([
    CollectionSummaryType.trash,
    CollectionSummaryType.archive,
    CollectionSummaryType.uncategorized,
    CollectionSummaryType.hidden,
]);
