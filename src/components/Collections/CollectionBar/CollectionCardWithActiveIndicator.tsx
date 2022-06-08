import React from 'react';
import { EnteFile } from 'types/file';
import {
    CollectionTileWrapper,
    ActiveIndicator,
    CollectionBarTile,
    CollectionBarTileText,
} from '../styledComponents';
import CollectionCard from '../CollectionCard';

interface Iprops {
    active: boolean;
    latestFile: EnteFile;
    collectionName: string;
    onClick: () => void;
}

const CollectionCardWithActiveIndicator = React.forwardRef(
    (props: Iprops, ref: any) => {
        const { active, collectionName, ...others } = props;

        return (
            <CollectionTileWrapper ref={ref}>
                <CollectionCard collectionTile={CollectionBarTile} {...others}>
                    <CollectionBarTileText>
                        {collectionName}
                    </CollectionBarTileText>
                </CollectionCard>
                {active && <ActiveIndicator />}
            </CollectionTileWrapper>
        );
    }
);

export default CollectionCardWithActiveIndicator;
