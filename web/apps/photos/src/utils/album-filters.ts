import {
    isBulkDeletableEmptyAlbum,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import { t } from "i18next";

export type AlbumFilter =
    "all" | "ente" | "shared" | "received" | "links" | "empty-albums";

export const albumFilters: {
    value: AlbumFilter;
    label: () => string;
    title: () => string;
}[] = [
    { value: "all", label: () => t("all"), title: () => t("all_albums") },
    {
        value: "shared",
        label: () => t("shared_albums_label"),
        title: () => t("shared_albums_title"),
    },
    {
        value: "received",
        label: () => t("received_albums_label"),
        title: () => t("received_albums_title"),
    },
    {
        value: "links",
        label: () => t("links_albums_label"),
        title: () => t("links_albums_title"),
    },
    {
        value: "empty-albums",
        label: () => t("empty_albums"),
        title: () => t("empty_albums_title"),
    },
];

export const matchesAlbumFilter = (
    cs: CollectionSummary,
    albumFilter: AlbumFilter,
): boolean => {
    switch (albumFilter) {
        case "all":
            return true;
        case "ente":
            return (
                cs.fileCount > 0 &&
                !cs.attributes.has("system") &&
                !cs.attributes.has("shared") &&
                !matchesAlbumFilter(cs, "shared") &&
                !matchesAlbumFilter(cs, "received") &&
                !matchesAlbumFilter(cs, "links")
            );
        case "shared":
            return (
                !cs.attributes.has("sharedIncoming") &&
                !cs.attributes.has("quickLink") &&
                (cs.attributes.has("sharedOutgoing") ||
                    cs.attributes.has("sharedViaLink"))
            );
        case "received":
            return cs.attributes.has("sharedIncoming");
        case "links":
            return cs.attributes.has("quickLink");
        case "empty-albums":
            return isBulkDeletableEmptyAlbum(cs);
    }
};

export const visibleAlbumFilters = (collectionSummaries: CollectionSummary[]) =>
    albumFilters.filter(({ value }) => {
        if (value == "all") return true;
        if (value == "empty-albums") {
            return (
                collectionSummaries.filter(isBulkDeletableEmptyAlbum).length >=
                3
            );
        }
        return collectionSummaries.some((cs) => matchesAlbumFilter(cs, value));
    });
