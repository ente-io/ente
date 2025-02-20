import { SpacedRow } from "@/base/components/containers";
import { DialogCloseIconButton } from "@/base/components/mui/DialogCloseIconButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import type { Collection } from "@/media/collection";
import {
    ItemCard,
    LargeTileButton,
    LargeTileCreateNewButton,
    LargeTileTextOverlay,
} from "@/new/photos/components/Tiles";
import {
    canAddToCollection,
    canMoveToCollection,
    CollectionSummaryOrder,
    type CollectionSummaries,
    type CollectionSummary,
} from "@/new/photos/services/collection/ui";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useState } from "react";

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
     * collection. In such cases, the ID of this collection can be set as the
     * {@link relatedCollectionID} to omit showing it in the list again.
     */
    relatedCollectionID?: number | undefined;
}

type CollectionSelectorProps = ModalVisibilityProps & {
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
    const isFullScreen = useMediaQuery("(max-width: 490px)");

    const [filteredCollections, setFilteredCollections] = useState<
        CollectionSummary[]
    >([]);

    useEffect(() => {
        if (!attributes || !open) {
            return;
        }

        const collections = [...collectionSummaries.values()]
            .filter(({ id, type }) => {
                if (id === attributes.relatedCollectionID) {
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
    }, [collectionSummaries, attributes, open, onClose]);

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
        <Dialog
            open={open}
            onClose={handleClose}
            fullWidth
            fullScreen={isFullScreen}
            slotProps={{ paper: { sx: { maxWidth: "490px" } } }}
        >
            <SpacedRow sx={{ padding: "10px 8px 6px 0" }}>
                <DialogTitle variant="h3">{titleForAction(action)}</DialogTitle>
                <DialogCloseIconButton onClose={handleClose} />
            </SpacedRow>

            <DialogContent_>
                <LargeTileCreateNewButton onClick={onCreateCollection}>
                    {t("create_albums")}
                </LargeTileCreateNewButton>
                {filteredCollections.map((collectionSummary) => (
                    <CollectionButton
                        key={collectionSummary.id}
                        collectionSummary={collectionSummary}
                        onCollectionClick={handleCollectionClick}
                    />
                ))}
            </DialogContent_>
        </Dialog>
    );
};

const DialogContent_ = styled(DialogContent)`
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
`;

const titleForAction = (action: CollectionSelectorAction) => {
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

interface CollectionButtonProps {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

const CollectionButton: React.FC<CollectionButtonProps> = ({
    collectionSummary,
    onCollectionClick,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        coverFile={collectionSummary.coverFile}
        onClick={() => onCollectionClick(collectionSummary.id)}
    >
        <LargeTileTextOverlay>
            <Typography>{collectionSummary.name}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);
