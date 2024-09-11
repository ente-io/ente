import ArchiveIcon from "@mui/icons-material/Archive";
import Favorite from "@mui/icons-material/FavoriteRounded";
import LinkIcon from "@mui/icons-material/Link";
import PeopleIcon from "@mui/icons-material/People";
import PushPin from "@mui/icons-material/PushPin";
import { Box, Typography, styled } from "@mui/material";
import Tooltip from "@mui/material/Tooltip";
import { CollectionSummary, CollectionSummaryType } from "types/collection";
import CollectionCard from "../CollectionCard";
import {
    ActiveIndicator,
    CollectionBarTile,
    CollectionBarTileIcon,
    CollectionBarTileText,
} from "../styledComponents";

interface Iprops {
    collectionSummary: CollectionSummary;
    activeCollectionID: number;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

const CollectionListBarCard = (props: Iprops) => {
    const { activeCollectionID, collectionSummary, onCollectionClick } = props;

    return (
        <Box>
            <CollectionCard
                collectionTile={CollectionBarTile}
                coverFile={collectionSummary.coverFile}
                onClick={() => {
                    onCollectionClick(collectionSummary.id);
                }}
            >
                <CollectionCardText collectionName={collectionSummary.name} />
                <CollectionCardIcon collectionType={collectionSummary.type} />
            </CollectionCard>
            {activeCollectionID === collectionSummary.id && <ActiveIndicator />}
        </Box>
    );
};

function CollectionCardText({ collectionName }) {
    return (
        <CollectionBarTileText>
            <TruncateText text={collectionName} />
        </CollectionBarTileText>
    );
}

function CollectionCardIcon({ collectionType }) {
    return (
        <CollectionBarTileIcon>
            {collectionType === CollectionSummaryType.favorites && <Favorite />}
            {collectionType === CollectionSummaryType.archived && (
                <ArchiveIcon
                    sx={(theme) => ({
                        color: theme.colors.white.muted,
                    })}
                />
            )}
            {collectionType === CollectionSummaryType.outgoingShare && (
                <PeopleIcon />
            )}
            {(collectionType === CollectionSummaryType.incomingShareViewer ||
                collectionType ===
                    CollectionSummaryType.incomingShareCollaborator) && (
                <PeopleIcon />
            )}
            {collectionType === CollectionSummaryType.sharedOnlyViaLink && (
                <LinkIcon />
            )}
            {collectionType === CollectionSummaryType.pinned && <PushPin />}
        </CollectionBarTileIcon>
    );
}

export default CollectionListBarCard;

const TruncateText = ({ text }) => {
    return (
        <Tooltip title={text}>
            <Box height={"2.1em"} overflow="hidden">
                <Ellipse variant="small" sx={{ wordBreak: "break-word" }}>
                    {text}
                </Ellipse>
            </Box>
        </Tooltip>
    );
};

const Ellipse = styled(Typography)`
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2; //number of lines to show
    line-clamp: 2;
    -webkit-box-orient: vertical;
`;
