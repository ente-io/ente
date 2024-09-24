import type { Collection } from "@/media/collection";
import {
    AllCollectionTile,
    ItemCard,
    LargeTileTextOverlay,
} from "@/new/photos/components/ItemCards";
import type {
    CollectionSummaries,
    CollectionSummary,
} from "@/new/photos/types/collection";
import { FlexWrapper } from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { DialogContent, Typography, useMediaQuery } from "@mui/material";
import { AllCollectionDialog } from "components/Collections/AllCollections/dialog";
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
import AddCollectionButton from "./AddCollectionButton";

export interface CollectionSelectorAttributes {
    callback: (collection: Collection) => void;
    showNextModal: () => void;
    intent: CollectionSelectorIntent;
    fromCollection?: number;
    onCancel?: () => void;
}

interface Props {
    open: boolean;
    onClose: () => void;
    attributes: CollectionSelectorAttributes;
    collections: Collection[];
    collectionSummaries: CollectionSummaries;
}
function CollectionSelector({
    attributes,
    collectionSummaries,
    collections,
    ...props
}: Props) {
    const isMobile = useMediaQuery("(max-width: 428px)");

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
        <AllCollectionDialog
            onClose={onUserTriggeredClose}
            open={props.open}
            position="center"
            fullScreen={isMobile}
            fullWidth={true}
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
        </AllCollectionDialog>
    );
}

export default CollectionSelector;

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
