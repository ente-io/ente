import { Typography } from "@mui/material";
import { t } from "i18next";
import { CollectionSummary } from "types/collection";
import CollectionCard from "../CollectionCard";
import { AllCollectionTile, AllCollectionTileText } from "../styledComponents";

interface Iprops {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

export default function AllCollectionCard({
    onCollectionClick,
    collectionSummary,
    isScrolling,
}: Iprops) {
    return (
        <CollectionCard
            collectionTile={AllCollectionTile}
            coverFile={collectionSummary.coverFile}
            onClick={() => onCollectionClick(collectionSummary.id)}
            isScrolling={isScrolling}
        >
            <AllCollectionTileText>
                <Typography>{collectionSummary.name}</Typography>
                <Typography variant="small" color="text.muted">
                    {t("photos_count", { count: collectionSummary.fileCount })}
                </Typography>
            </AllCollectionTileText>
        </CollectionCard>
    );
}
