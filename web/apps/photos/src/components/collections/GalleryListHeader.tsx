import {
    CollectionShare,
    type CollectionShareIntent,
    type CollectionShareProps,
} from "@/components/collections/CollectionShare";
import type { FileListHeaderOrFooter } from "@/components/FileList";
import { PeopleHeader } from "@/components/gallery/PeopleHeader";
import type { GalleryBarMode } from "@/components/gallery/reducer";
import { useModalVisibility } from "ente-base/components/utils/modal";
import type { Collection } from "ente-media/collection";
import {
    GalleryItemsHeaderAdapter,
    GalleryItemsSummary,
} from "ente-new/photos/components/gallery/ListHeader";
import {
    PseudoCollectionID,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import type { Person } from "ente-new/photos/services/ml/people";
import React, { useCallback, useState, type ReactNode } from "react";
import { AlbumCastDialog } from "./AlbumCastDialog";
import {
    CollectionHeader,
    type CollectionHeaderProps,
} from "./CollectionHeader";

type GalleryListHeaderProps = {
    mode: GalleryBarMode;
    shouldHide: boolean;
    collectionSummary: CollectionSummary | undefined;
    activeCollection: Collection | undefined;
    activePerson: Person | undefined;
    people: Person[];
    setActiveCollectionID: (collectionID: number) => void;
    onSelectPerson: (personID: string) => void;
    children: (header: FileListHeaderOrFooter | undefined) => ReactNode;
    hasActiveFileSelection: boolean;
} & Pick<
    CollectionHeaderProps,
    | "isActiveCollectionDownloadInProgress"
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

// Keep dialog and measurement state outside the virtualized header, so they
// survive header remounts and switching between the file list and overview views.
export const GalleryListHeader: React.FC<GalleryListHeaderProps> = ({
    shouldHide,
    mode,
    user,
    collectionSummary,
    activeCollection,
    setActiveCollectionID,
    setBlockingLoad,
    people,
    onSelectPerson,
    isActiveCollectionDownloadInProgress,
    hasActiveFileSelection,
    activePerson,
    emailByUserID,
    shareSuggestionEmails,
    onRemotePull,
    onEditAlbumDetails,
    onAddSaveGroup,
    onShowMap,
    onCollectionSlideshow,
    children,
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

    const albumDescription =
        activeCollection?.pubMagicMetadata?.data.caption?.trim();
    const [descriptionHeight, setDescriptionHeight] = useState(0);

    // Pseudo-collections need header actions despite having no Collection.
    const shouldRenderCollectionHeader =
        mode != "people" &&
        collectionSummary &&
        (activeCollection || collectionSummary.id <= PseudoCollectionID.all);

    const header: FileListHeaderOrFooter | undefined =
        shouldHide || mode == "links"
            ? undefined
            : {
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
                          onSelectPerson={onSelectPerson}
                      />
                  ) : (
                      <></>
                  ),
                  height: 72 + (albumDescription ? descriptionHeight : 0),
              };

    return (
        <>
            {children(header)}
            {!shouldHide && activeCollection && (
                <>
                    <CollectionShare
                        {...collectionShareVisibilityProps}
                        onClose={closeCollectionShare}
                        collectionSummary={collectionSummary!}
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
