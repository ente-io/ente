import React from 'react';
import { Collection } from 'types/collection';

import ManageAddViewer from '../ShareControl/ManageAddViewer';
import ManageAddCollab from './MangeAddCollab';
import ManageParticipants from './ManageParticipants';
import { CollectionSummaryType } from 'constants/collection';

export default function ShareControl({
    collection,
    onRootClose,
    collectionSummaryType,
}: {
    collection: Collection;
    onRootClose: () => void;
    collectionSummaryType: CollectionSummaryType;
}) {
    console.log('collectionSummaryType', collectionSummaryType);
    collectionSummaryType === CollectionSummaryType.incomingShareViewer
        ? console.log('incomingShareViewer')
        : console.log('not incomingShareViewer');
    return (
        <>
            {collectionSummaryType === CollectionSummaryType.outgoingShare && (
                <>
                    {collection.sharees.length > 0 ? (
                        <ManageParticipants
                            collection={collection}
                            onRootClose={onRootClose}
                        />
                    ) : null}
                    <ManageAddViewer
                        collection={collection}
                        onRootClose={onRootClose}
                    />
                    <ManageAddCollab
                        collection={collection}
                        onRootClose={onRootClose}
                    />
                </>
            )}
        </>
    );
}
