import type { EnteFile } from "@/new/photos/types/file";

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
