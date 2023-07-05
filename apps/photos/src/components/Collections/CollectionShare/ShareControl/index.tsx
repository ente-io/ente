import React from 'react';
import { Collection } from 'types/collection';

import ManageAddViewer from '../ShareControl/ManageAddViewer';
import ManageAddCollab from './MangeAddCollab';
import ManageParticipants from './ManageParticipants';

export default function ShareControl({
    collection,
    onRootClose,
}: {
    collection: Collection;
    onRootClose: () => void;
}) {
    return (
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
    );
}
