import {
    isBulkDeletableEmptyAlbum,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import { t } from "i18next";

export type AlbumFilter =
    "ente" | "shared" | "received" | "links" | "empty-albums";

export const albumFilters: {
    value: AlbumFilter;
    label: () => string;
    title: () => string;
}[] = [
    { value: "ente", label: () => "Ente", title: () => "Ente" },
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
        case "ente":
            return (
                !cs.attributes.has("system") &&
                !cs.attributes.has("uncategorized") &&
                !cs.attributes.has("quickLink") &&
                !cs.attributes.has("archived") &&
                !(cs.type == "userFavorites" && cs.fileCount == 0)
            );
        case "shared":
            return (
                !cs.attributes.has("archived") &&
                !cs.attributes.has("sharedIncoming") &&
                !cs.attributes.has("quickLink") &&
                (cs.attributes.has("sharedOutgoing") ||
                    cs.attributes.has("sharedViaLink"))
            );
        case "received":
            return (
                !cs.attributes.has("archived") &&
                cs.attributes.has("sharedIncoming")
            );
        case "links":
            return cs.attributes.has("quickLink");
        case "empty-albums":
            return isBulkDeletableEmptyAlbum(cs);
    }
};

export const visibleAlbumFilters = (collectionSummaries: CollectionSummary[]) =>
    albumFilters.filter(({ value }) => {
        if (value == "ente") return true;
        if (value == "empty-albums") {
            return (
                collectionSummaries.filter(isBulkDeletableEmptyAlbum).length >=
                3
            );
        }
        return collectionSummaries.some((cs) => matchesAlbumFilter(cs, value));
    });

export type AlbumSearchRow =
    | { type: "group"; filter: AlbumFilter }
    | {
          type: "collection";
          filter: AlbumFilter;
          collectionSummary: CollectionSummary;
      };

export const searchAlbumRows = (
    collectionSummaries: CollectionSummary[],
    query: string,
): AlbumSearchRow[] => {
    const search = query.trim().toLowerCase();
    const matches = collectionSummaries.filter((cs) =>
        cs.name.toLowerCase().includes(search),
    );
    return visibleAlbumFilters(collectionSummaries).flatMap<AlbumSearchRow>(
        ({ value }) => {
            const albums = matches.filter((cs) =>
                matchesAlbumFilter(cs, value),
            );
            return albums.length
                ? [
                      { type: "group", filter: value },
                      ...albums.map((collectionSummary): AlbumSearchRow => ({
                          type: "collection",
                          filter: value,
                          collectionSummary,
                      })),
                  ]
                : [];
        },
    );
};
