import React from 'react';
import {
    ActiveIndicator,
    CollectionBarTile,
    CollectionBarTileIcon,
    CollectionBarTileText,
} from '../styledComponents';
import CollectionCard from '../CollectionCard';
import TruncateText from 'components/TruncateText';
import { Box } from '@mui/material';
import { CollectionSummaryType } from 'constants/collection';
import Favorite from '@mui/icons-material/FavoriteRounded';
import ArchiveIcon from '@mui/icons-material/Archive';
import PeopleIcon from '@mui/icons-material/People';
import LinkIcon from '@mui/icons-material/Link';
import { CollectionSummary } from 'types/collection';
import PushPin from '@mui/icons-material/PushPin';

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
                }}>
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
