import { useLocalState } from "@ente/shared/hooks/useLocalState";
import { LS_KEYS } from "@ente/shared/storage/localStorage";
import AllCollections from "components/Collections/AllCollections";
import CollectionInfoWithOptions from "components/Collections/CollectionInfoWithOptions";
import CollectionListBar from "components/Collections/CollectionListBar";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import CollectionShare from "components/Collections/CollectionShare";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import { ALL_SECTION, COLLECTION_LIST_SORT_BY } from "constants/collection";
import { useCallback, useEffect, useMemo, useState } from "react";
import { sortCollectionSummaries } from "services/collectionService";
import { Collection, CollectionSummaries } from "types/collection";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
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

interface Iprops {
    activeCollection: Collection;
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    isInSearchMode: boolean;
    isInHiddenSection: boolean;
    collectionSummaries: CollectionSummaries;
    hiddenCollectionSummaries: CollectionSummaries;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
    filesDownloadProgressAttributesList: FilesDownloadProgressAttributes[];
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
}

export default function Collections(props: Iprops) {
    const {
        activeCollection,
        isInSearchMode,
        isInHiddenSection,
        activeCollectionID,
        setActiveCollectionID,
        collectionSummaries,
        hiddenCollectionSummaries,
        setCollectionNamerAttributes,
        setPhotoListHeader,
        filesDownloadProgressAttributesList,
        setFilesDownloadProgressAttributesCreator,
    } = props;

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
            isInHiddenSection ? hiddenCollectionSummaries : collectionSummaries,
        [isInHiddenSection, hiddenCollectionSummaries, collectionSummaries],
    );

    const shouldBeHidden = useMemo(
        () =>
            isInSearchMode ||
            (!hasNonSystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === ALL_SECTION),
        [isInSearchMode, toShowCollectionSummaries, activeCollectionID],
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
        if (isInSearchMode) {
            return;
        }
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
        toShowCollectionSummaries,
        activeCollectionID,
        isInSearchMode,
        isActiveCollectionDownloadInProgress,
    ]);

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
                isInHiddenSection={isInHiddenSection}
                activeCollectionID={activeCollectionID}
                setActiveCollectionID={setActiveCollectionID}
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldBeShownOnCollectionBar(x.type),
                )}
                showAllCollections={openAllCollections}
                setCollectionListSortBy={setCollectionListSortBy}
                collectionListSortBy={collectionListSortBy}
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
                isInHiddenSection={isInHiddenSection}
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
}
