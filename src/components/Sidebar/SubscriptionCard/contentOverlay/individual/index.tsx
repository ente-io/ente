import React from 'react';
import { UserDetails } from 'types/user';
import StorageSection from '../storageSection';
import { IndividualUsageSection } from './usageSection';

interface Iprops {
    userDetails: UserDetails;
}

export function IndividualSubscriptionCardContent({ userDetails }: Iprops) {
    return (
        <>
            <StorageSection
                storage={userDetails.subscription.storage}
                usage={userDetails.usage}
            />
            <IndividualUsageSection
                usage={userDetails.usage}
                fileCount={userDetails.fileCount}
                storage={userDetails.subscription.storage}
            />
        </>
    );
}
