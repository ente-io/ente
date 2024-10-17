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
 */
export interface CollectionSummary {
    /** The "UI" type for the collection. */
    type: CollectionSummaryType;
    id: number;
    name: string;
    coverFile: EnteFile | undefined;
    latestFile: EnteFile;
    fileCount: number;
    updationTime: number;
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
