import type { Collection } from "@/media/collection";
import type { Person } from "@/new/photos/services/ml/cgroups";
import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import AllCollections from "components/Collections/AllCollections";
import CollectionInfoWithOptions from "components/Collections/CollectionInfoWithOptions";
import {
    CollectionListBar,
    type CollectionListBarProps,
} from "components/Collections/CollectionListBar";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import CollectionShare from "components/Collections/CollectionShare";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import { useCallback, useEffect, useMemo, useState } from "react";
import { sortCollectionSummaries } from "services/collectionService";
import { CollectionSummaries } from "types/collection";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    ALL_SECTION,
    COLLECTION_LIST_SORT_BY,
    hasNonSystemCollections,
    isSystemCollection,
    shouldBeShownOnCollectionBar,
} from "utils/collection";
import {
    FilesDownloadProgressAttributes,
    isFilesDownloadCancelled,
    isFilesDownloadCompleted,
} from "../FilesDownloadProgress";
import AlbumCastDialog from "./CollectionOptions/AlbumCastDialog";

interface CollectionsProps {
    mode: CollectionListBarProps["mode"] | "search";
    collectionSummaries: CollectionSummaries;
    activeCollection: Collection;
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    hiddenCollectionSummaries: CollectionSummaries;
    people: Person[];
    activePerson: Person | undefined;
    setActivePerson: (id: Person | undefined) => void;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
    filesDownloadProgressAttributesList: FilesDownloadProgressAttributes[];
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
}

export const Collections: React.FC<CollectionsProps> = ({
    mode,
    collectionSummaries,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    hiddenCollectionSummaries,
    people,
    activePerson,
    setActivePerson,
    setCollectionNamerAttributes,
    setPhotoListHeader,
    filesDownloadProgressAttributesList,
    setFilesDownloadProgressAttributesCreator,
}) => {
    const [allCollectionView, setAllCollectionView] = useState(false);
    const [collectionShareModalView, setCollectionShareModalView] =
        useState(false);

    const [showAlbumCastDialog, setShowAlbumCastDialog] = useState(false);

    const [collectionListSortBy, setCollectionListSortBy] =
        useLocalState<COLLECTION_LIST_SORT_BY>(
            LS_KEYS.COLLECTION_SORT_BY,
            COLLECTION_LIST_SORT_BY.UPDATION_TIME_DESCENDING,
        );

    const toShowCollectionSummaries = useMemo(
        () =>
            mode == "hidden-albums"
                ? hiddenCollectionSummaries
                : collectionSummaries,
        [mode, hiddenCollectionSummaries, collectionSummaries],
    );

    const shouldBeHidden = useMemo(
        () =>
            mode == "search" ||
            (!hasNonSystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === ALL_SECTION),
        [mode, toShowCollectionSummaries, activeCollectionID],
    );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...toShowCollectionSummaries.values()],
                collectionListSortBy,
            ),
        [collectionListSortBy, toShowCollectionSummaries],
    );

    const isActiveCollectionDownloadInProgress = useCallback(() => {
        const attributes = filesDownloadProgressAttributesList.find(
            (attr) => attr.collectionID === activeCollectionID,
        );
        return (
            attributes &&
            !isFilesDownloadCancelled(attributes) &&
            !isFilesDownloadCompleted(attributes)
        );
    }, [activeCollectionID, filesDownloadProgressAttributesList]);

    useEffect(() => {
        if (mode == "search") return;

        setPhotoListHeader({
            item: (
                <CollectionInfoWithOptions
                    collectionSummary={toShowCollectionSummaries.get(
                        activeCollectionID,
                    )}
                    activeCollection={activeCollection}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    showCollectionShareModal={() =>
                        setCollectionShareModalView(true)
                    }
                    setFilesDownloadProgressAttributesCreator={
                        setFilesDownloadProgressAttributesCreator
                    }
                    isActiveCollectionDownloadInProgress={
                        isActiveCollectionDownloadInProgress
                    }
                    setActiveCollectionID={setActiveCollectionID}
                    setShowAlbumCastDialog={setShowAlbumCastDialog}
                />
            ),
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [
        mode,
        toShowCollectionSummaries,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
    ]);

    if (mode == "search") return <></>;
    if (shouldBeHidden) {
        return <></>;
    }

    const closeAllCollections = () => setAllCollectionView(false);
    const openAllCollections = () => setAllCollectionView(true);
    const closeCollectionShare = () => setCollectionShareModalView(false);
    const closeAlbumCastDialog = () => setShowAlbumCastDialog(false);

    return (
        <>
            <CollectionListBar
                {...{
                    mode,
                    activeCollectionID,
                    setActiveCollectionID,
                    people,
                    activePerson,
                    setActivePerson,
                    collectionListSortBy,
                    setCollectionListSortBy,
                }}
                onShowAllCollections={openAllCollections}
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldBeShownOnCollectionBar(x.type),
                )}
            />

            <AllCollections
                open={allCollectionView}
                onClose={closeAllCollections}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (x) => !isSystemCollection(x.type),
                )}
                setActiveCollectionID={setActiveCollectionID}
                setCollectionListSortBy={setCollectionListSortBy}
                collectionListSortBy={collectionListSortBy}
                isInHiddenSection={mode == "hidden-albums"}
            />

            <CollectionShare
                collectionSummary={toShowCollectionSummaries.get(
                    activeCollectionID,
                )}
                open={collectionShareModalView}
                onClose={closeCollectionShare}
                collection={activeCollection}
            />
            <AlbumCastDialog
                currentCollection={activeCollection}
                show={showAlbumCastDialog}
                onHide={closeAlbumCastDialog}
            />
        </>
    );
};
