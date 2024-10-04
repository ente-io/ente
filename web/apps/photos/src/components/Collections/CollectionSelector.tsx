import type { Collection } from "@/media/collection";
import {
    AllCollectionTile,
    ItemCard,
    ItemTileOverlay,
    LargeTileTextOverlay,
} from "@/new/photos/components/ItemCards";
import type {
    CollectionSummaries,
    CollectionSummary,
} from "@/new/photos/types/collection";
import { FlexWrapper } from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import {
    Dialog,
    DialogContent,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { createUnCategorizedCollection } from "services/collectionService";
import { CollectionSelectorIntent } from "types/gallery";
import {
    COLLECTION_SORT_ORDER,
    DUMMY_UNCATEGORIZED_COLLECTION,
    isAddToAllowedCollection,
    isMoveToAllowedCollection,
} from "utils/collection";

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    intent: CollectionSelectorIntent;
    fromCollection?: number;
    onCancel?: () => void;
}

interface CollectionSelectorProps {
    open: boolean;
    onClose: () => void;
    attributes: CollectionSelectorAttributes;
    collections: Collection[];
    collectionSummaries: CollectionSummaries;
}

export const CollectionSelector: React.FC<CollectionSelectorProps> = ({
    attributes,
    collectionSummaries,
    collections,
    ...props
}) => {
    // Make the dialog fullscreen if the screen is <= the dialog's max width.
    const isFullScreen = useMediaQuery("(max-width: 494px)");

    const [collectionsToShow, setCollectionsToShow] = useState<
        CollectionSummary[]
    >([]);

    useEffect(() => {
        if (!attributes || !props.open) {
            return;
        }
        const main = async () => {
            const collectionsToShow = [...collectionSummaries.values()]
                ?.filter(({ id, type }) => {
                    if (id === attributes.fromCollection) {
                        return false;
                    } else if (
                        attributes.intent === CollectionSelectorIntent.add
                    ) {
                        return isAddToAllowedCollection(type);
                    } else if (
                        attributes.intent === CollectionSelectorIntent.upload
                    ) {
                        return (
                            isMoveToAllowedCollection(type) ||
                            type == "uncategorized"
                        );
                    } else if (
                        attributes.intent === CollectionSelectorIntent.restore
                    ) {
                        return (
                            isMoveToAllowedCollection(type) ||
                            type == "uncategorized"
                        );
                    } else {
                        return isMoveToAllowedCollection(type);
                    }
                })
                .sort((a, b) => {
                    return a.name.localeCompare(b.name);
                })
                .sort((a, b) => {
                    return (
                        COLLECTION_SORT_ORDER.get(a.type) -
                        COLLECTION_SORT_ORDER.get(b.type)
                    );
                });
            if (collectionsToShow.length === 0) {
                props.onClose();
                attributes.showNextModal();
            }
            setCollectionsToShow(collectionsToShow);
        };
        main();
    }, [collectionSummaries, attributes, props.open]);

    if (!collectionsToShow?.length) {
        return <></>;
    }

    const handleCollectionClick = async (collectionID: number) => {
        let selectedCollection: Collection;
        if (collectionID === DUMMY_UNCATEGORIZED_COLLECTION) {
            const uncategorizedCollection =
                await createUnCategorizedCollection();
            selectedCollection = uncategorizedCollection;
        } else {
            selectedCollection = collections.find((c) => c.id === collectionID);
        }
        attributes.callback(selectedCollection);
        props.onClose();
    };

    const onUserTriggeredClose = () => {
        attributes.onCancel?.();
        props.onClose();
    };

    return (
        <Dialog_
            onClose={onUserTriggeredClose}
            open={props.open}
            fullScreen={isFullScreen}
            fullWidth
        >
            <DialogTitleWithCloseButton onClose={onUserTriggeredClose}>
                {attributes.intent === CollectionSelectorIntent.upload
                    ? t("upload_to_album")
                    : attributes.intent === CollectionSelectorIntent.add
                      ? t("add_to_album")
                      : attributes.intent === CollectionSelectorIntent.move
                        ? t("move_to_album")
                        : attributes.intent === CollectionSelectorIntent.restore
                          ? t("restore_to_album")
                          : attributes.intent ===
                              CollectionSelectorIntent.unhide
                            ? t("unhide_to_album")
                            : t("select_album")}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ "&&&": { padding: 0 } }}>
                <FlexWrapper flexWrap="wrap" gap={"4px"} padding={"16px"}>
                    <AddCollectionButton
                        showNextModal={attributes.showNextModal}
                    />
                    {collectionsToShow.map((collectionSummary) => (
                        <CollectionSelectorCard
                            key={collectionSummary.id}
                            collectionSummary={collectionSummary}
                            onCollectionClick={handleCollectionClick}
                        />
                    ))}
                </FlexWrapper>
            </DialogContent>
        </Dialog_>
    );
};

export const AllCollectionMobileBreakpoint = 559;

export const Dialog_ = styled(Dialog)(({ theme }) => ({
    "& .MuiPaper-root": {
        maxWidth: "494px",
    },
    "& .MuiDialogTitle-root": {
        padding: "16px",
        paddingRight: theme.spacing(1),
    },
    "& .MuiDialogContent-root": {
        padding: "16px",
    },
}));

interface CollectionSelectorCardProps {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

const CollectionSelectorCard: React.FC<CollectionSelectorCardProps> = ({
    collectionSummary,
    onCollectionClick,
}) => (
    <ItemCard
        TileComponent={AllCollectionTile}
        coverFile={collectionSummary.coverFile}
        onClick={() => onCollectionClick(collectionSummary.id)}
    >
        <LargeTileTextOverlay>
            <Typography>{collectionSummary.name}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);

interface AddCollectionButtonProps {
    showNextModal: () => void;
}

const AddCollectionButton: React.FC<AddCollectionButtonProps> = ({
    showNextModal,
}) => (
    <ItemCard TileComponent={AllCollectionTile} onClick={showNextModal}>
        <LargeTileTextOverlay>{t("create_albums")}</LargeTileTextOverlay>
        <ImageContainer>+</ImageContainer>
    </ItemCard>
);

const ImageContainer = styled(ItemTileOverlay)`
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 42px;
`;
