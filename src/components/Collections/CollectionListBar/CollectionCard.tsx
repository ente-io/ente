import React from 'react';
import { EnteFile } from 'types/file';
import {
    ActiveIndicator,
    CollectionBarTile,
    CollectionBarTileText,
} from '../styledComponents';
import CollectionCard from '../CollectionCard';
import TruncateText from 'components/TruncateText';
import { Box } from '@mui/material';

interface Iprops {
    active: boolean;
    latestFile: EnteFile;
    collectionName: string;
    onClick: () => void;
}

const CollectionListBarCard = React.forwardRef((props: Iprops, ref: any) => {
    const { active, collectionName, ...others } = props;

    return (
        <Box ref={ref}>
            <CollectionCard collectionTile={CollectionBarTile} {...others}>
                <CollectionBarTileText zIndex={1}>
                    <TruncateText text={collectionName} />
                </CollectionBarTileText>
            </CollectionCard>
            {active && <ActiveIndicator />}
        </Box>
    );
});

export default CollectionListBarCard;
