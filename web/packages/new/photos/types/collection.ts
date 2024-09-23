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
    coverFile: EnteFile;
    latestFile: EnteFile;
    fileCount: number;
    updationTime: number;
    order?: number;
}

export type CollectionSummaries = Map<number, CollectionSummary>;

/**
 * Sort orders for use when we're showing lists of collections (e.g. in the
 * collection bar).
 */
export enum CollectionListSortBy {
    Name,
    CreationTimeAscending,
    UpdationTimeDescending,
}
