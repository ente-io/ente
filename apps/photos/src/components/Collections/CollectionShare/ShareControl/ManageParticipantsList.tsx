import { Box } from '@mui/material';

import React from 'react';
// import { t } from 'i18next';
import { Collection } from 'types/collection';
import { OwnerParticipant } from './OwnerParticipant';
import { ViewerParticipants } from './ViewerParticipants';
import { CollaboratorParticipants } from './CollaboratorParticipants';

interface Iprops {
    collection: Collection;
}

export function ManageParticipantsList({ collection }: Iprops) {
    if (!collection.sharees?.length) {
        return <></>;
    }

    return (
        <Box mb={3}>
            <OwnerParticipant collection={collection}></OwnerParticipant>
            <CollaboratorParticipants
                collection={collection}></CollaboratorParticipants>
            <ViewerParticipants collection={collection}></ViewerParticipants>
        </Box>
    );
}
