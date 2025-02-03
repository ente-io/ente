import type { EnteFile } from "@/media/file";

export type CollectionSummaryType =
    | "folder"
    | "favorites"
    | "album"
    | "archive"
    | "trash"
    | "uncategorized"
    | "all"
    | "outgoingShare"
    | "incomingShareViewer"
    | "incomingShareCollaborator"
    | "sharedOnlyViaLink"
    | "archived"
    | "defaultHidden"
    | "hiddenItems"
    | "pinned";

/**
 * A massaged version of a real or pseudo- {@link Collection} suitable for being
 * directly shown in the UI.
 *
 * TODO: Rename me to CollectionOrSection? FileGroup? FileListing?
 * Known sections:
 * - DUMMY_UNCATEGORIZED_COLLECTION
 * - ALL_SECTION
 * - TRASH_SECTION
 * - HIDDEN_ITEMS_SECTION
 * - ARCHIVE_SECTION
 */
export interface CollectionSummary {
    /**
     * The ID of the underlying collection, or one of the predefined placeholder
     * IDs for the pseudo-collections.
     */
    id: number;
    /**
     * The "UI" type for the collection or pseudo-collection.
     *
     * For newer code consider using {@link attributes} instead.
     */
    type: CollectionSummaryType;
    /**
     * Various UI related attributes for the collection or pseudo-collection.
     *
     * This is meant to replace {@link type} gradually.
     */
    attributes: CollectionSummaryType[];
    /**
     * The name of the collection or pseudo-collection.
     */
    name: string;
    /**
     * The newest file in the collection or pseudo-collection (if it is not
     * empty).
     */
    latestFile: EnteFile | undefined;
    /**
     * The file to show as the cover for the collection or pseudo-collection.
     *
     * This can be one of
     * - A file explicitly chosen by the user.
     * - The latest file.
     * - The oldest file (if the user has set a reverse sort on the collection).
     */
    coverFile: EnteFile | undefined;
    /**
     * The number of files in the underlying collection, or the number of files
     * that belong to this pseudo-collection.
     */
    fileCount: number;
    /**
     * The time when the collection was last updated. For pseudo-collections
     * this will (usually) be the updation time of the latest file that it
     * contains.
     */
    updationTime: number | undefined;
    order?: number;
}

export type CollectionSummaries = Map<number, CollectionSummary>;

/**
 * The sort schemes that can be used when we're showing list of collections
 * (e.g. in the collection bar).
 *
 * This is the list of all possible values, see {@link CollectionsSortBy} for
 * the type.
 */
export const collectionsSortBy = [
    "name",
    "creation-time-asc",
    "updation-time-desc",
] as const;

/**
 * Type of individual {@link collectionsSortBy} values.
 */
export type CollectionsSortBy = (typeof collectionsSortBy)[number];

/**
 * An ordering of collection "categories".
 *
 * Within each category, the collections are sorted by the applicable
 * {@link CollectionsSortBy}.
 */
export const CollectionSummaryOrder = new Map<CollectionSummaryType, number>([
    ["all", 0],
    ["hiddenItems", 0],
    ["uncategorized", 1],
    ["favorites", 2],
    ["pinned", 3],
    ["album", 4],
    ["folder", 4],
    ["incomingShareViewer", 4],
    ["incomingShareCollaborator", 4],
    ["outgoingShare", 4],
    ["sharedOnlyViaLink", 4],
    ["archived", 4],
    ["archive", 5],
    ["trash", 6],
    ["defaultHidden", 7],
]);

const systemCSTypes = new Set<CollectionSummaryType>([
    "all",
    "archive",
    "trash",
    "uncategorized",
    "hiddenItems",
    "defaultHidden",
]);

const addToDisabledCSTypes = new Set<CollectionSummaryType>([
    ...systemCSTypes,
    "incomingShareViewer",
]);

const moveToDisabledCSTypes = new Set<CollectionSummaryType>([
    ...addToDisabledCSTypes,
    "incomingShareCollaborator",
]);

const hideFromCollectionBarCSTypes = new Set<CollectionSummaryType>([
    "trash",
    "archive",
    "uncategorized",
    "defaultHidden",
]);

export const isSystemCollection = (type: CollectionSummaryType) =>
    systemCSTypes.has(type);

export const areOnlySystemCollections = (
    collectionSummaries: CollectionSummaries,
) =>
    [...collectionSummaries.values()].every(({ type }) =>
        isSystemCollection(type),
    );

export const canAddToCollection = (type: CollectionSummaryType) =>
    !addToDisabledCSTypes.has(type);

export const canMoveToCollection = (type: CollectionSummaryType) =>
    !moveToDisabledCSTypes.has(type);

export const shouldShowOnCollectionBar = (type: CollectionSummaryType) =>
    !hideFromCollectionBarCSTypes.has(type);
