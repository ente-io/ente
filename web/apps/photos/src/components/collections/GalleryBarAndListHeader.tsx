// TODO: Audit this file
import {
    CollectionShare,
    type CollectionShareIntent,
    type CollectionShareProps,
} from "@/components/collections/CollectionShare";
import type { FileListHeaderOrFooter } from "@/components/FileList";
import {
    GalleryBarImpl,
    type GalleryBarImplProps,
} from "@/components/gallery/BarImpl";
import { PeopleHeader } from "@/components/gallery/PeopleHeader";
import { sortPeople } from "@/utils/people-sort";
import { useModalVisibility } from "ente-base/components/utils/modal";
import {
    isSaveCancelled,
    isSaveComplete,
    type SaveGroup,
} from "ente-gallery/components/utils/save-groups";
import type { Collection } from "ente-media/collection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import {
    PseudoCollectionID,
    type CollectionSummaries,
} from "ente-new/photos/services/collection-summary";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { AlbumCastDialog } from "./AlbumCastDialog";
import {
    CollectionHeader,
    type CollectionHeaderProps,
} from "./CollectionHeader";

export type GalleryBarAndListHeaderProps = GalleryBarImplProps & {
    shouldHide: boolean;
    barCollectionSummaries: CollectionSummaries;
    activeCollection: Collection | undefined;
    setActiveCollectionID: (collectionID: number) => void;
    onSelectPersonInHeader: GalleryBarImplProps["onSelectPerson"];
    setFileListHeader: (header: FileListHeaderOrFooter) => void;
    hasActiveFileSelection: boolean;
    saveGroups: SaveGroup[];
} & Pick<
        CollectionHeaderProps,
        | "onRemotePull"
        | "onAddSaveGroup"
        | "onEditAlbumDetails"
        | "onShowMap"
        | "onCollectionSlideshow"
    > &
    Pick<
        CollectionShareProps,
        "user" | "emailByUserID" | "shareSuggestionEmails" | "setBlockingLoad"
    >;

// TODO: Move this back into the gallery once its responsibilities are split.
export const GalleryBarAndListHeader: React.FC<
    GalleryBarAndListHeaderProps
> = ({
    shouldHide,
    mode,
    user,
    barCollectionSummaries: toShowCollectionSummaries,
    collectionSummaries,
    visibleAlbumFilters,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    normalCollectionSummaries,
    uncategorizedCollectionSummaryID,
    onShowCollectionSummary,
    activeCollection,
    activeCollectionID,
    setActiveCollectionID,
    onSelectCollectionID,
    setBlockingLoad,
    people,
    peopleSortBy,
    onChangePeopleSortBy,
    albumFilter,
    albumSearchQuery,
    onAlbumSearchQueryChange,
    onShowAlbumOverview,
    onShowPeopleOverview,
    onCreateAlbum,
    onSelectPerson,
    onSelectPersonInHeader,
    saveGroups,
    hasActiveFileSelection,
    activePerson,
    emailByUserID,
    shareSuggestionEmails,
    onRemotePull,
    onEditAlbumDetails,
    onAddSaveGroup,
    onShowMap,
    onCollectionSlideshow,
    setFileListHeader,
    collapsed,
    mobileDrawerProps,
}) => {
    const { show: showCollectionShare, props: collectionShareVisibilityProps } =
        useModalVisibility();
    const { show: showCollectionCast, props: collectionCastVisibilityProps } =
        useModalVisibility();
    const [collectionShareIntent, setCollectionShareIntent] =
        useState<CollectionShareIntent>();

    const openCollectionShare = useCallback(() => {
        setCollectionShareIntent(undefined);
        showCollectionShare();
    }, [showCollectionShare]);

    const openCollectionManageLink = useCallback(() => {
        setCollectionShareIntent("manage-link");
        showCollectionShare();
    }, [showCollectionShare]);

    const closeCollectionShare = useCallback(() => {
        setCollectionShareIntent(undefined);
        collectionShareVisibilityProps.onClose();
    }, [collectionShareVisibilityProps]);

    const sortedPeople = useMemo(
        () => sortPeople(people, peopleSortBy),
        [people, peopleSortBy],
    );

    const isActiveCollectionDownloadInProgress = useCallback(() => {
        const group = saveGroups.find(
            (g) => g.collectionSummaryID === activeCollectionID,
        );
        return !!group && !isSaveComplete(group) && !isSaveCancelled(group);
    }, [saveGroups, activeCollectionID]);

    const albumDescription =
        activeCollection?.pubMagicMetadata?.data.caption?.trim();
    const [descriptionHeight, setDescriptionHeight] = useState(0);

    useEffect(() => {
        if (shouldHide || mode == "links") return;

        const collectionSummary = toShowCollectionSummaries.get(
            activeCollectionID!,
        );
        // Pseudo-collections need header actions despite having no Collection.
        const shouldRenderCollectionHeader =
            mode != "people" &&
            collectionSummary &&
            (activeCollection ||
                collectionSummary.id <= PseudoCollectionID.all);

        setFileListHeader({
            component: shouldRenderCollectionHeader ? (
                <CollectionHeader
                    {...{
                        activeCollection,
                        setActiveCollectionID,
                        isActiveCollectionDownloadInProgress,
                        onRemotePull,
                        onAddSaveGroup,
                        onShowMap,
                        onCollectionSlideshow,
                    }}
                    collectionSummary={collectionSummary}
                    onCollectionShare={openCollectionShare}
                    onCollectionManageLink={openCollectionManageLink}
                    onCollectionCast={showCollectionCast}
                    onEditAlbumDetails={onEditAlbumDetails}
                    hasActiveFileSelection={hasActiveFileSelection}
                    onDescriptionHeightChange={setDescriptionHeight}
                />
            ) : mode != "people" && collectionSummary ? (
                <GalleryItemsHeaderAdapter>
                    <GalleryItemsSummary
                        name={collectionSummary.name}
                        fileCount={collectionSummary.fileCount}
                    />
                </GalleryItemsHeaderAdapter>
            ) : activePerson ? (
                <PeopleHeader
                    person={activePerson}
                    people={people}
                    onSelectPerson={onSelectPersonInHeader}
                />
            ) : (
                <></>
            ),
            height: 72 + (albumDescription ? descriptionHeight : 0),
        });
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [
        shouldHide,
        mode,
        toShowCollectionSummaries,
        activeCollection,
        activeCollectionID,
        isActiveCollectionDownloadInProgress,
        activePerson,
        showCollectionShare,
        openCollectionShare,
        openCollectionManageLink,
        showCollectionCast,
        hasActiveFileSelection,
        onRemotePull,
        onAddSaveGroup,
        onShowMap,
        onCollectionSlideshow,
        onEditAlbumDetails,
        albumDescription,
        descriptionHeight,
        // TODO: Cluster
        // This causes a loop since it is an array dep
        // people,
    ]);

    if (shouldHide) {
        return <></>;
    }

    return (
        <>
            <GalleryBarImpl
                {...{
                    mode,
                    albumFilter,
                    albumSearchQuery,
                    onAlbumSearchQueryChange,
                    onShowAlbumOverview,
                    onShowPeopleOverview,
                    onCreateAlbum,
                    onSelectCollectionID,
                    onSelectPerson,
                    activeCollectionID,
                    people: sortedPeople,
                    activePerson,
                    collectionsSortBy,
                    onChangeCollectionsSortBy,
                    collectionSummaries,
                    visibleAlbumFilters,
                    peopleSortBy,
                    collapsed,
                    mobileDrawerProps,
                    normalCollectionSummaries,
                    uncategorizedCollectionSummaryID,
                    onShowCollectionSummary,
                }}
                onChangePeopleSortBy={onChangePeopleSortBy}
            />

            {activeCollection && (
                <>
                    <CollectionShare
                        {...collectionShareVisibilityProps}
                        onClose={closeCollectionShare}
                        collectionSummary={toShowCollectionSummaries.get(
                            activeCollectionID!,
                        )!}
                        collection={activeCollection}
                        intent={collectionShareIntent}
                        {...{
                            user,
                            emailByUserID,
                            shareSuggestionEmails,
                            setBlockingLoad,
                            onRemotePull,
                        }}
                    />
                    <AlbumCastDialog
                        {...collectionCastVisibilityProps}
                        collection={activeCollection}
                    />
                </>
            )}
        </>
    );
};
