import type { EnteFile } from "@/new/photos/types/file";

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

export interface CollectionSummary {
    id: number;
    name: string;
    type: CollectionSummaryType;
    coverFile: EnteFile;
    latestFile: EnteFile;
    fileCount: number;
    updationTime: number;
    order?: number;
}

export type CollectionSummaries = Map<number, CollectionSummary>;
export type CollectionFilesCount = Map<number, number>;
