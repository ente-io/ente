import { Typography } from "@mui/material";
import { CollectionSummary } from "types/collection";
import CollectionCard from "../CollectionCard";
import { AllCollectionTile, AllCollectionTileText } from "../styledComponents";

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
            <AllCollectionTileText>
                <Typography>{collectionSummary.name}</Typography>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
