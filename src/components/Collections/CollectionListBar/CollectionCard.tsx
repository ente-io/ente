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
import ArchiveOutlined from '@mui/icons-material/ArchiveOutlined';
import GroupIcon from '@mui/icons-material/Group';

interface Iprops {
    active: boolean;
    latestFile: EnteFile;
    collectionName: string;
    collectionType: CollectionSummaryType;
    onClick: () => void;
}

const CollectionListBarCard = React.forwardRef((props: Iprops, ref: any) => {
    const { active, collectionName, collectionType, ...others } = props;

    return (
        <Box ref={ref}>
            <CollectionCard collectionTile={CollectionBarTile} {...others}>
                <CollectionCardText collectionName={collectionName} />
                <CollectionCardIcon collectionType={collectionType} />
            </CollectionCard>
            {active && <ActiveIndicator />}
        </Box>
    );
});

export default CollectionListBarCard;

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
                <ArchiveOutlined />
            )}
            {collectionType === CollectionSummaryType.shared && <GroupIcon />}
        </CollectionBarTileIcon>
    );
}
