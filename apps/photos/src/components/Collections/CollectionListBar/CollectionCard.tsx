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

interface Iprops {
    collectionSummary: CollectionSummary;
    activeCollection: number;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

const CollectionListBarCard = (props: Iprops) => {
    const { activeCollection, collectionSummary, onCollectionClick } = props;

    return (
        <Box>
            <CollectionCard
                collectionTile={CollectionBarTile}
                latestFile={collectionSummary.latestFile}
                onClick={() => {
                    onCollectionClick(collectionSummary.id);
                }}>
                <CollectionCardText collectionName={collectionSummary.name} />
                <CollectionCardIcon collectionType={collectionSummary.type} />
            </CollectionCard>
            {activeCollection === collectionSummary.id && <ActiveIndicator />}
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
        </CollectionBarTileIcon>
    );
}

export default CollectionListBarCard;
