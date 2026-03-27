import type { CollectionType } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";

export type CollectionSummaryType =
    | CollectionType
    | "all"
    | "hiddenItems"
    | "defaultHidden"
    | "archiveItems"
    | "trash"
    | "userFavorites"
    | "sharedIncoming";

export type CollectionSummaryAttribute =
    | CollectionSummaryType
    | "shared"
    | "sharedOutgoing"
    | "sharedIncomingViewer"
    | "sharedIncomingCollaborator"
    | "sharedIncomingAdmin"
    | "sharedOnlyViaLink"
    | "system"
    | "archived"
    | "hideFromCollectionBar"
    | "pinned"
    | "shareePinned";

/**
 * ID of pseudo-collections that the public albums UI reuses from the photos app.
 */
export const PseudoCollectionID = {
    all: 0,
    archiveItems: -1,
    trash: -2,
    uncategorizedPlaceholder: -3,
    hiddenItems: -4,
} as const;

/**
 * Minimal collection summary shape required by the vendored viewer sidebars.
 */
export interface CollectionSummary {
    id: number;
    attributes: Set<CollectionSummaryAttribute>;
    name: string;
    coverFile: EnteFile | undefined;
}

/**
 * Collection summaries indexed by collection ID.
 */
export type CollectionSummaries = Map<number, CollectionSummary>;
