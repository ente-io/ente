import React from 'react';
import { EnteFile } from 'types/file';
import {
    CollectionTileWrapper,
    ActiveIndicator,
    CollectionTile,
} from '../styledComponents';
import CollectionCard from '../CollectionCard';

const CollectionCardWithActiveIndicator = React.forwardRef(
    (
        props: {
            children;
            active: boolean;
            latestFile: EnteFile;
            onClick: () => void;
        },
        ref: any
    ) => {
        const { active, ...others } = props;

        return (
            <CollectionTileWrapper ref={ref}>
                <CollectionCard collectionTile={CollectionTile} {...others} />
                {active && <ActiveIndicator />}
            </CollectionTileWrapper>
        );
    }
);

export default CollectionCardWithActiveIndicator;
