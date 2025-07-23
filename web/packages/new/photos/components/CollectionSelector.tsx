import {
    Dialog,
    DialogContent,
    DialogTitle,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import type { Collection } from "ente-media/collection";
import {
    ItemCard,
    LargeTileButton,
    LargeTileCreateNewButton,
    LargeTileTextOverlay,
} from "ente-new/photos/components/Tiles";
import {
    canAddToCollection,
    canMoveToCollection,
    type CollectionSummaries,
    type CollectionSummary,
} from "ente-new/photos/services/collection-summary";
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
     * Some actions, like "add" and "move", happen in the context of an existing
     * collection summary.
     *
     * In such cases, the ID of the collection summary can be set as the
     * {@link sourceCollectionID} to omit showing it in the list again.
     */
    sourceCollectionSummaryID?: number;
    /**
     * Callback invoked when the user selects the option to create a new
     * collection.
     */
    onCreateCollection: () => void;
    /**
     * Callback invoked when the user selects one the existing collections
     * listed in the dialog.
     */
    onSelectCollection: (collection: Collection) => void;
    /**
     * Callback invoked when the user cancels the collection selection dialog.
     */
    onCancel?: () => void;
}

type CollectionSelectorProps = ModalVisibilityProps & {
    /**
     * The same {@link CollectionSelector} can be used for different
     * purposes by customizing the {@link attributes} prop before opening it.
     */
    attributes: CollectionSelectorAttributes | undefined;
    /**
     * The collections to list.
     *
     * The picker does not list all of the collection summaries, it filters
     * these provided list down to values which make sense for the
     * {@link attribute}'s {@link action}.
     *
     * See: [Note: Picking from selectable collection summaries].
     */
    collectionSummaries: CollectionSummaries;
    /**
     * A function to map from a collection summary ID to a {@link Collection}.
     *
     * This is invoked when the user makes a selection, to convert the ID of the
     * selected collection summary into a collection object that can be passed
     * as the {@link callback} property of {@link CollectionSelectorAttributes}.
     *
     * [Note: Picking from selectable collection summaries]
     *
     * In general, not all pseudo collections can be converted into a
     * collection. For example, there is no underlying collection corresponding
     * to the "All" pseudo collection. However, the implementation of
     * {@link CollectionSelector} is such that it filters the provided
     * {@link collectionSummaries} to only show those which, when selected, can
     * be mapped to an (existing or on-demand created) collection.
     */
    collectionForCollectionSummaryID: (
        collectionID: number,
    ) => Promise<Collection>;
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
    collectionForCollectionSummaryID,
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
            .filter((cs) => {
                if (cs.id === attributes.sourceCollectionSummaryID) {
                    return false;
                } else if (attributes.action == "add") {
                    return canAddToCollection(cs);
                } else if (attributes.action == "upload") {
                    return (
                        canMoveToCollection(cs) || cs.type == "uncategorized"
                    );
                } else if (attributes.action == "restore") {
                    return (
                        canMoveToCollection(cs) || cs.type == "uncategorized"
                    );
                } else {
                    return canMoveToCollection(cs);
                }
            })
            .sort((a, b) => a.name.localeCompare(b.name))
            .sort((a, b) => b.sortPriority - a.sortPriority);

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

    const handleCollectionSummaryClick = async (id: number) => {
        onSelectCollection(await collectionForCollectionSummaryID(id));
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
                    <CollectionSummaryButton
                        key={collectionSummary.id}
                        collectionSummary={collectionSummary}
                        onClick={handleCollectionSummaryClick}
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

interface CollectionSummaryButtonProps {
    collectionSummary: CollectionSummary;
    onClick: (collectionSummaryID: number) => void;
}

const CollectionSummaryButton: React.FC<CollectionSummaryButtonProps> = ({
    collectionSummary,
    onClick,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        coverFile={collectionSummary.coverFile}
        onClick={() => onClick(collectionSummary.id)}
    >
        <LargeTileTextOverlay>
            <Typography>{collectionSummary.name}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);
