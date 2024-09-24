import type { Collection } from "@/media/collection";
import type { Person } from "@/new/photos/services/ml/cgroups";
import {
    collectionsSortBy,
    type CollectionsSortBy,
    type CollectionSummaries,
} from "@/new/photos/types/collection";
import { includes } from "@/utils/type-guards";
import {
    getData,
    LS_KEYS,
    removeData,
} from "@ente/shared/storage/localStorage";
import AllCollections from "components/Collections/AllCollections";
import CollectionInfoWithOptions from "components/Collections/CollectionInfoWithOptions";
import {
    CollectionListBar,
    type GalleryBarMode,
} from "components/Collections/CollectionListBar";
import { SetCollectionNamerAttributes } from "components/Collections/CollectionNamer";
import CollectionShare from "components/Collections/CollectionShare";
import { ITEM_TYPE, TimeStampListItem } from "components/PhotoList";
import { useCallback, useEffect, useMemo, useState } from "react";
import { sortCollectionSummaries } from "services/collectionService";
import { SetFilesDownloadProgressAttributesCreator } from "types/gallery";
import {
    ALL_SECTION,
    hasNonSystemCollections,
    isSystemCollection,
    shouldBeShownOnCollectionBar,
} from "utils/collection";
import {
    FilesDownloadProgressAttributes,
    isFilesDownloadCancelled,
    isFilesDownloadCompleted,
} from "../FilesDownloadProgress";
import { AlbumCastDialog } from "./AlbumCastDialog";

interface CollectionsProps {
    /** `true` if the bar should be hidden altogether. */
    shouldHide: boolean;
    /** otherwise show stuff that belongs to this mode. */
    mode: GalleryBarMode;
    setMode: (mode: GalleryBarMode) => void;
    collectionSummaries: CollectionSummaries;
    activeCollection: Collection;
    activeCollectionID?: number;
    setActiveCollectionID: (id?: number) => void;
    hiddenCollectionSummaries: CollectionSummaries;
    people: Person[];
    activePerson: Person | undefined;
    onSelectPerson: (person: Person) => void;
    setCollectionNamerAttributes: SetCollectionNamerAttributes;
    setPhotoListHeader: (value: TimeStampListItem) => void;
    filesDownloadProgressAttributesList: FilesDownloadProgressAttributes[];
    setFilesDownloadProgressAttributesCreator: SetFilesDownloadProgressAttributesCreator;
}

// TODO-Cluster Rename me to GalleryBar and subsume GalleryBarImpl
export const Collections: React.FC<CollectionsProps> = ({
    shouldHide,
    mode,
    setMode,
    collectionSummaries,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    hiddenCollectionSummaries,
    people,
    activePerson,
    onSelectPerson,
    setCollectionNamerAttributes,
    setPhotoListHeader,
    filesDownloadProgressAttributesList,
    setFilesDownloadProgressAttributesCreator,
}) => {
    const [openAllCollectionDialog, setOpenAllCollectionDialog] =
        useState(false);
    const [openCollectionShareView, setOpenCollectionShareView] =
        useState(false);
    const [openAlbumCastDialog, setOpenAlbumCastDialog] = useState(false);

    const [collectionsSortBy, setCollectionsSortBy] =
        useCollectionsSortByLocalState("updation-time-desc");

    const toShowCollectionSummaries = useMemo(
        () =>
            mode == "hidden-albums"
                ? hiddenCollectionSummaries
                : collectionSummaries,
        [mode, hiddenCollectionSummaries, collectionSummaries],
    );

    const shouldBeHidden = useMemo(
        () =>
            shouldHide ||
            (!hasNonSystemCollections(toShowCollectionSummaries) &&
                activeCollectionID === ALL_SECTION),
        [shouldHide, toShowCollectionSummaries, activeCollectionID],
    );

    const sortedCollectionSummaries = useMemo(
        () =>
            sortCollectionSummaries(
                [...toShowCollectionSummaries.values()],
                collectionsSortBy,
            ),
        [collectionsSortBy, toShowCollectionSummaries],
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
        if (shouldHide) return;

        setPhotoListHeader({
            item: (
                <CollectionInfoWithOptions
                    collectionSummary={toShowCollectionSummaries.get(
                        activeCollectionID,
                    )}
                    activeCollection={activeCollection}
                    setCollectionNamerAttributes={setCollectionNamerAttributes}
                    showCollectionShareModal={() =>
                        setOpenCollectionShareView(true)
                    }
                    setFilesDownloadProgressAttributesCreator={
                        setFilesDownloadProgressAttributesCreator
                    }
                    isActiveCollectionDownloadInProgress={
                        isActiveCollectionDownloadInProgress
                    }
                    setActiveCollectionID={setActiveCollectionID}
                    setShowAlbumCastDialog={setOpenAlbumCastDialog}
                />
            ),
            itemType: ITEM_TYPE.HEADER,
            height: 68,
        });
    }, [
        shouldHide,
        mode,
        toShowCollectionSummaries,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
        people,
        activePerson,
    ]);

    if (shouldBeHidden) {
        return <></>;
    }

    return (
        <>
            <CollectionListBar
                {...{
                    mode,
                    setMode,
                    activeCollectionID,
                    setActiveCollectionID,
                    people,
                    activePerson,
                    onSelectPerson,
                    collectionsSortBy,
                }}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                onShowAllCollections={() => setOpenAllCollectionDialog(true)}
                collectionSummaries={sortedCollectionSummaries.filter((x) =>
                    shouldBeShownOnCollectionBar(x.type),
                )}
            />

            <AllCollections
                open={openAllCollectionDialog}
                onClose={() => setOpenAllCollectionDialog(false)}
                collectionSummaries={sortedCollectionSummaries.filter(
                    (x) => !isSystemCollection(x.type),
                )}
                setActiveCollectionID={setActiveCollectionID}
                onChangeCollectionsSortBy={setCollectionsSortBy}
                collectionsSortBy={collectionsSortBy}
                isInHiddenSection={mode == "hidden-albums"}
            />
            <CollectionShare
                collectionSummary={toShowCollectionSummaries.get(
                    activeCollectionID,
                )}
                open={openCollectionShareView}
                onClose={() => setOpenCollectionShareView(false)}
                collection={activeCollection}
            />
            <AlbumCastDialog
                open={openAlbumCastDialog}
                onClose={() => setOpenAlbumCastDialog(false)}
                collection={activeCollection}
            />
        </>
    );
};

/**
 * A hook that maintains the collections sort order both as in-memory and local
 * storage state.
 */
const useCollectionsSortByLocalState = (initialValue: CollectionsSortBy) => {
    const key = "collectionsSortBy";

    const [value, setValue] = useState(initialValue);

    useEffect(() => {
        const value = localStorage.getItem(key);
        if (value) {
            if (includes(collectionsSortBy, value)) setValue(value);
        } else {
            // Older versions of this code used to store the value in a
            // different place and format. Migrate if needed.
            //
            // This migration added Sep 2024, can be removed after a bit (esp
            // since it effectively runs on each app start). (tag: Migration).
            const oldData = getData(LS_KEYS.COLLECTION_SORT_BY);
            if (oldData) {
                let newValue: CollectionsSortBy | undefined;
                switch (oldData.value) {
                    case 0:
                        newValue = "name";
                        break;
                    case 1:
                        newValue = "creation-time-asc";
                        break;
                    case 2:
                        newValue = "updation-time-desc";
                        break;
                }
                if (newValue) {
                    localStorage.setItem(key, newValue);
                    setValue(newValue);
                }
                removeData(LS_KEYS.COLLECTION_SORT_BY);
            }
        }
    }, []);

    const setter = (value: CollectionsSortBy) => {
        localStorage.setItem(key, value);
        setValue(value);
    };

    return [value, setter] as const;
};
