import type { CollectionType } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";

export type CollectionSummaryType =
    | CollectionType
    | "all"
    | "archive"
    | "trash"
    | "hiddenItems"
    | "defaultHidden"
    | "outgoingShare"
    | "incomingShareViewer"
    | "incomingShareCollaborator"
    | "sharedOnlyViaLink"
    | "archived"
    | "pinned";

/**
 * ID of the special {@link CollectionSummary} instances that are not backed by
 * a real {@link Collection}.
 */
export const CollectionSummaryID = {
    /**
     * The "All" section.
     *
     * The default view when the user opens the gallery, showing the unique
     * non-hidden and non-archived files in their collections.
     */
    all: 0,
    /**
     * The items shown in the "Archive" section.
     *
     * It shows the files that the user has individually archived.
     */
    archive: -1,
    /**
     * Trash
     *
     * This shows files that are in the user's trash - files that have been
     * deleted, but have not yet been deleted permanently.
     */
    trash: -2,
    /**
     * A placeholder for the uncategorized collection used till it is empty.
     *
     * The user's sole "uncategorized" collection is created on demand the first
     * time we need to move a file out of the last collection it belonged to
     * (yet retain the file).
     *
     * Until the real uncategorized collection comes into existence, we use this
     * dummy placeholder collection as the {@link CollectionSummary} that gets
     * shown if the user navigates to the "Uncategorized" section in the UI.
     */
    placeholderUncategorizedCollection: -3,
    /**
     * The default collection shown in the "Hidden" section.
     *
     * It shows the files that the user has individually hidden; effectively, it
     * works as a consolidated combination of all of the user's "default hidden"
     * albums (See: Note: Multiple "default" hidden collections]).
     *
     * In addition to this "Hidden items" collection, the "Hidden" section also
     * shows albums that were hidden.
     */
    mergedDefaultHiddenCollection: -4,
} as const;

export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_COLLECTION = -3;
export const HIDDEN_ITEMS_SECTION = -4;
export const ALL_SECTION = 0;

/**
 * A massaged version of a collection (real or placeholder) or a pseudo
 * "section" suitable for being directly shown in the UI.
 *
 * From one perspective, this can be thought of as a "CollectionOrSection":
 * i.e., a group of files listed together in the UI, with the files coming from
 * a real "collection" or some special "section". In the first case, the
 * underlying listing will be backed by a {@link Collection}, while in the
 * second case the files and other attributes comprising the listing will be
 * determined by the special case-specific rules for that particular section.
 *
 * Even when this is backed by a corresponding {@link Collection}, it adds some
 * extra attributes that make it easier and more efficient for the UI elements
 * to render this collection summary directly. From that perspective, this can
 * be thought of as a "UICollection".
 */
export interface CollectionSummary {
    /**
     * The ID of the underlying {@link Collection}, or one of the predefined
     * {@link CollectionSummaryID}s for sections and other pseudo-collections.
     */
    id: number;
    /**
     * The primary "UI" type for the collection or section or pseudo-collection.
     *
     * For newer code consider using {@link attributes} instead.
     */
    type: CollectionSummaryType;
    /**
     * Various UI related attributes of the collection or section or
     * pseudo-collection.
     *
     * This is meant to replace {@link type} gradually. It defines various
     * attributes about the underlying file listing that this collection summary
     * stands for which the UI elements rendering the collection summary might
     * want to know.
     */
    attributes: CollectionSummaryType[];
    /**
     * The name of the collection or section or pseudo-collection surfaced in
     * the UI.
     */
    name: string;
    /**
     * The newest file in the collection or section or pseudo-collection (if it
     * is not empty).
     */
    latestFile: EnteFile | undefined;
    /**
     * The file to show as the cover for the collection or section or
     * pseudo-collection.
     *
     * This can be one of
     * - A file explicitly chosen by the user.
     * - The latest file.
     * - The oldest file (if the user has set a reverse sort on the collection).
     */
    coverFile: EnteFile | undefined;
    /**
     * The number of files in the underlying collection, or the number of files
     * that belong to this section or pseudo-collection.
     */
    fileCount: number;
    /**
     * The time (epoch microseconds) when the collection was last updated. For
     * sections or pseudo-collections this will (usually) be the updation time
     * of the latest file that it contains.
     */
    updationTime: number | undefined;
    order?: number;
}

/**
 * Collection summaries, indexed by their IDs.
 */
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
