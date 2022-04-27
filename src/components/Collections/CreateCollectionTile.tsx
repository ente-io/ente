import React from 'react';
import constants from 'utils/strings/englishConstants';
import { CollectionTitleWithDashedBorder } from './styledComponents';

export const CreateNewCollectionTile = (props) => {
    return (
        <CollectionTitleWithDashedBorder {...props}>
            <div>{constants.NEW} </div>
            <div>{'+'}</div>
        </CollectionTitleWithDashedBorder>
    );
};
