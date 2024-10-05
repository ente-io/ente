import type { Collection } from "@/media/collection";
import {
    AllCollectionTile,
    ItemCard,
    ItemTileOverlay,
    LargeTileTextOverlay,
} from "@/new/photos/components/ItemCards";
import {
    canAddToCollection,
    canMoveToCollection,
    CollectionSummaryOrder,
    type CollectionSummaries,
    type CollectionSummary,
} from "@/new/photos/services/collection/ui";
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

export enum CollectionSelectorIntent {
    upload,
    add,
    move,
    restore,
    unhide,
}

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    /**
     * The {@link intent} modifies the title of the dialog, and also filters
     * the list of collections the user can select from appropriately.
     */
    intent: CollectionSelectorIntent;
    fromCollection?: number;
    onCancel?: () => void;
}

interface CollectionSelectorProps {
    open: boolean;
    onClose: () => void;
    attributes: CollectionSelectorAttributes;
    collectionSummaries: CollectionSummaries;
    /**
     * A function to map from a collection ID to a {@link Collection}.
     *
     * This is invoked when the user makes a selection, to convert the ID of the
     * selected collection into a collection object that can be passed to the
     * {@link callback} attribute of {@link CollectionSelectorAttributes}.
     */
    collectionForCollectionID: (collectionID: number) => Promise<Collection>;
}

/**
 * A dialog allowing the user to select one of their existing collections or
 * create a new one.
 */
export const CollectionSelector: React.FC<CollectionSelectorProps> = ({
    attributes,
    collectionSummaries,
    collectionForCollectionID,
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
                        return canAddToCollection(type);
                    } else if (
                        attributes.intent === CollectionSelectorIntent.upload
                    ) {
                        return (
                            canMoveToCollection(type) || type == "uncategorized"
                        );
                    } else if (
                        attributes.intent === CollectionSelectorIntent.restore
                    ) {
                        return (
                            canMoveToCollection(type) || type == "uncategorized"
                        );
                    } else {
                        return canMoveToCollection(type);
                    }
                })
                .sort((a, b) => {
                    return a.name.localeCompare(b.name);
                })
                .sort((a, b) => {
                    return (
                        CollectionSummaryOrder.get(a.type) -
                        CollectionSummaryOrder.get(b.type)
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
        attributes.callback(await collectionForCollectionID(collectionID));
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
