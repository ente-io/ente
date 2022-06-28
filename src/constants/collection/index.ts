export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const ALL_SECTION = 0;

export enum CollectionType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
    archive = 'archive',
    trash = 'trash',
    all = 'all',
    shared = 'shared',
}

export enum COLLECTION_SORT_BY {
    NAME,
    CREATION_TIME_ASCENDING,
    CREATION_TIME_DESCENDING,
    UPDATION_TIME_DESCENDING,
}

export const COLLECTION_SHARE_DEFAULT_VALID_DURATION =
    10 * 24 * 60 * 60 * 1000 * 1000;
export const COLLECTION_SHARE_DEFAULT_DEVICE_LIMIT = 4;

export const COLLECTION_SORT_ORDER = new Map([
    [CollectionType.all, 0],
    [CollectionType.favorites, 1],
    [CollectionType.album, 2],
    [CollectionType.folder, 2],
    [CollectionType.shared, 2],
    [CollectionType.archive, 3],
    [CollectionType.trash, 4],
]);

export const SYSTEM_COLLECTION_TYPES = new Set([
    CollectionType.all,
    CollectionType.archive,
    CollectionType.trash,
]);

export const UPLOAD_ALLOWED_COLLECTION_TYPES = new Set([
    CollectionType.album,
    CollectionType.folder,
    CollectionType.favorites,
]);

export const OPTIONS_HAVING_COLLECTION_TYPES = new Set([
    CollectionType.folder,
    CollectionType.album,
    CollectionType.trash,
]);

export const HIDE_FROM_COLLECTION_BAR_TYPES = new Set([
    CollectionType.trash,
    CollectionType.archive,
]);
