import React from 'react';
import { EnteFile } from 'types/file';
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

interface Iprops {
    active: boolean;
    latestFile: EnteFile;
    collectionName: string;
    collectionType: CollectionSummaryType;
    onClick: () => void;
    isScrolling?: boolean;
}

const CollectionListBarCard = (props: Iprops) => {
    const { active, collectionName, collectionType, ...others } = props;

    return (
        <Box>
            <CollectionCard collectionTile={CollectionBarTile} {...others}>
                <CollectionCardText collectionName={collectionName} />
                <CollectionCardIcon collectionType={collectionType} />
            </CollectionCard>
            {active && <ActiveIndicator />}
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
            {collectionType === CollectionSummaryType.incomingShare && (
                <PeopleIcon />
            )}
            {collectionType === CollectionSummaryType.sharedOnlyViaLink && (
                <LinkIcon />
            )}
        </CollectionBarTileIcon>
    );
}

export default CollectionListBarCard;
