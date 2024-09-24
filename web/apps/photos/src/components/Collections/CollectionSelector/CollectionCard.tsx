import {
    AllCollectionTile,
    LargeTileTextOverlay,
} from "@/new/photos/components/ItemCards";
import type { CollectionSummary } from "@/new/photos/types/collection";
import { Typography } from "@mui/material";
import CollectionCard from "../CollectionCard";

interface Iprops {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
}

export default function CollectionSelectorCard({
    onCollectionClick,
    collectionSummary,
}: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            coverFile={collectionSummary.coverFile}
            onClick={() => onCollectionClick(collectionSummary.id)}
        >
            <LargeTileTextOverlay>
                <Typography>{collectionSummary.name}</Typography>
            </LargeTileTextOverlay>
        </CollectionCard>
    );
}
