import React, { useMemo } from 'react';
import StorageSection from './storageSection';
import { isPartOfFamily } from 'utils/billing';
import { SpaceBetweenFlex } from 'components/Container';
import { UsageSection } from './usageSection';

export function SubscriptionCardContent({ userDetails }) {
    const totalUsage = useMemo(() => {
        if (isPartOfFamily(userDetails.familyData)) {
            return userDetails.familyData.members.reduce(
                (sum, currentMember) => sum + currentMember.usage,
                0
            );
        } else {
            return userDetails.usage;
        }
    }, [userDetails]);

    const totalStorage = useMemo(() => {
        if (isPartOfFamily(userDetails.familyData)) {
            return userDetails.familyData.storage;
        } else {
            return userDetails.subscription.storage;
        }
    }, [userDetails]);

    return (
        <SpaceBetweenFlex
            height={'100%'}
            flexDirection={'column'}
            padding={'20px 16px'}>
            <StorageSection
                totalStorage={totalStorage}
                totalUsage={totalUsage}
            />
            <UsageSection userDetails={userDetails} />
        </SpaceBetweenFlex>
    );
}
