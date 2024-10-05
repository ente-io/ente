// TODO
/* eslint-disable @typescript-eslint/no-non-null-assertion */
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
import React, { useEffect, useState } from "react";
import type { DialogVisibilityProps } from "./mui/Dialog";

export type CollectionSelectorAction =
    | "upload"
    | "add"
    | "move"
    | "restore"
    | "unhide";

export interface CollectionSelectorAttributes {
    /**
     * The {@link action} modifies the title of the dialog, and also removes
     * some system collections that don't might not make sense for that
     * particular action.
     */
    action: CollectionSelectorAction;
    /**
     * Callback invoked when the user selects one the existing collections
     * listed in the dialog.
     */
    onSelectCollection: (collection: Collection) => void;
    /**
     * Callback invoked when the user selects the option to create a new
     * collection.
     */
    onCreateCollection: () => void;
    /**
     * Callback invoked when the user cancels the collection selection dialog.
     */
    onCancel?: () => void;
    /**
     * Some actions, like "add" and "move", happen in the context of an existing
     * collection. In such cases, their ID can be set as the
     * {@link ignoredCollectionID} to omit showing them again in the list of
     * collections.
     */
    ignoredCollectionID?: number | undefined;
}

type CollectionSelectorProps = DialogVisibilityProps & {
    /**
     * The same {@link CollectionSelector} can be used for different
     * purposes by customizing the {@link attributes} prop before opening it.
     */
    attributes: CollectionSelectorAttributes | undefined;
    /**
     * The collections to list.
     */
    collectionSummaries: CollectionSummaries;
    /**
     * A function to map from a collection ID to a {@link Collection}.
     *
     * This is invoked when the user makes a selection, to convert the ID of the
     * selected collection into a collection object that can be passed to the
     * {@link callback} attribute of {@link CollectionSelectorAttributes}.
     */
    collectionForCollectionID: (collectionID: number) => Promise<Collection>;
};

/**
 * A dialog allowing the user to select one of their existing collections or
 * create a new one.
 */
export const CollectionSelector: React.FC<CollectionSelectorProps> = ({
    open,
    onClose,
    attributes,
    collectionSummaries,
    collectionForCollectionID,
}) => {
    // Make the dialog fullscreen if the screen is <= the dialog's max width.
    const isFullScreen = useMediaQuery("(max-width: 494px)");

    const [filteredCollections, setFilteredCollections] = useState<
        CollectionSummary[]
    >([]);

    useEffect(() => {
        if (!attributes || !open) {
            return;
        }

        const collections = [...collectionSummaries.values()]
            .filter(({ id, type }) => {
                if (id === attributes.ignoredCollectionID) {
                    return false;
                } else if (attributes.action == "add") {
                    return canAddToCollection(type);
                } else if (attributes.action == "upload") {
                    return canMoveToCollection(type) || type == "uncategorized";
                } else if (attributes.action == "restore") {
                    return canMoveToCollection(type) || type == "uncategorized";
                } else {
                    return canMoveToCollection(type);
                }
            })
            .sort((a, b) => {
                return a.name.localeCompare(b.name);
            })
            .sort((a, b) => {
                return (
                    CollectionSummaryOrder.get(a.type)! -
                    CollectionSummaryOrder.get(b.type)!
                );
            });

        if (collections.length === 0) {
            onClose();
            attributes.onCreateCollection();
        }

        setFilteredCollections(collections);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [collectionSummaries, attributes, open]);

    if (!filteredCollections.length) {
        return <></>;
    }

    if (!attributes) {
        return <></>;
    }

    const { action, onSelectCollection, onCancel, onCreateCollection } =
        attributes;

    const handleCollectionClick = async (collectionID: number) => {
        onSelectCollection(await collectionForCollectionID(collectionID));
        onClose();
    };

    const handleClose = () => {
        onCancel?.();
        onClose();
    };

    return (
        <Dialog_
            open={open}
            onClose={handleClose}
            fullScreen={isFullScreen}
            fullWidth
        >
            <DialogTitleWithCloseButton onClose={handleClose}>
                {dialogTitleForAction(action)}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ "&&&": { padding: 0 } }}>
                <FlexWrapper flexWrap="wrap" gap={"4px"} padding={"16px"}>
                    <AddCollectionButton onClick={onCreateCollection} />
                    {filteredCollections.map((collectionSummary) => (
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

const Dialog_ = styled(Dialog)(({ theme }) => ({
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

const dialogTitleForAction = (action: CollectionSelectorAction) => {
    switch (action) {
        case "upload":
            return t("upload_to_album");
        case "add":
            return t("add_to_album");
        case "move":
            return t("move_to_album");
        case "restore":
            return t("restore_to_album");
        case "unhide":
            return t("unhide_to_album");
    }
};

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
    onClick: () => void;
}

const AddCollectionButton: React.FC<AddCollectionButtonProps> = ({
    onClick,
}) => (
    <ItemCard TileComponent={AllCollectionTile} onClick={onClick}>
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
