import { CollectionSummaryType } from 'constants/collection';
import { OwnerParticipant } from './emailShare/OwnerParticipant';
import { ShareDetailsCollab } from './emailShare/SharingDetailsCollab';
import { SharingDetailsViewers } from './emailShare/SharingDetailsViewers';

export default function SharingDetails({ type, collection }) {
    return (
        <>
            <OwnerParticipant collection={collection} />
            {type === CollectionSummaryType.incomingShareViewer && (
                <SharingDetailsViewers collection={collection} />
            )}

            {type === CollectionSummaryType.incomingShareCollaborator && (
                <>
                    <SharingDetailsViewers collection={collection} />

                    <ShareDetailsCollab collection={collection} />
                </>
            )}
        </>
    );
}
