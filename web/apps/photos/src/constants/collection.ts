export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_COLLECTION = -3;
export const HIDDEN_ITEMS_SECTION = -4;
export const ALL_SECTION = 0;

export enum CollectionType {
    folder = "folder",
    favorites = "favorites",
    album = "album",
    uncategorized = "uncategorized",
}

export enum CollectionSummaryType {
    folder = "folder",
    favorites = "favorites",
    album = "album",
    archive = "archive",
    trash = "trash",
    uncategorized = "uncategorized",
    all = "all",
    outgoingShare = "outgoingShare",
    incomingShareViewer = "incomingShareViewer",
    incomingShareCollaborator = "incomingShareCollaborator",
    sharedOnlyViaLink = "sharedOnlyViaLink",
    archived = "archived",
    defaultHidden = "defaultHidden",
    hiddenItems = "hiddenItems",
    pinned = "pinned",
}
export enum COLLECTION_LIST_SORT_BY {
    NAME,
    CREATION_TIME_ASCENDING,
    UPDATION_TIME_DESCENDING,
}

export const COLLECTION_SORT_ORDER = new Map([
    [CollectionSummaryType.all, 0],
    [CollectionSummaryType.hiddenItems, 0],
    [CollectionSummaryType.uncategorized, 1],
    [CollectionSummaryType.favorites, 2],
    [CollectionSummaryType.pinned, 3],
    [CollectionSummaryType.album, 4],
    [CollectionSummaryType.folder, 4],
    [CollectionSummaryType.incomingShareViewer, 4],
    [CollectionSummaryType.incomingShareCollaborator, 4],
    [CollectionSummaryType.outgoingShare, 4],
    [CollectionSummaryType.sharedOnlyViaLink, 4],
    [CollectionSummaryType.archived, 4],
    [CollectionSummaryType.archive, 5],
    [CollectionSummaryType.trash, 6],
    [CollectionSummaryType.defaultHidden, 7],
]);

