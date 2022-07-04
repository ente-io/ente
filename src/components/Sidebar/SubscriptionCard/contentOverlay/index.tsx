import { IndividualSubscriptionCardContent } from './individual';
import { FamilySubscriptionCardContent } from './family';
import React from 'react';
import { hasNonAdminFamilyMembers } from 'utils/billing';
import { SpaceBetweenFlex } from 'components/Container';
import { UserDetails } from 'types/user';

interface Iprops {
    userDetails: UserDetails;
}

export function SubscriptionCardContent({ userDetails }: Iprops) {
    return (
        <SpaceBetweenFlex
            height={'100%'}
            flexDirection={'column'}
            padding={'20px 16px'}>
            {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                <FamilySubscriptionCardContent userDetails={userDetails} />
            ) : (
                <IndividualSubscriptionCardContent userDetails={userDetails} />
            )}
        </SpaceBetweenFlex>
    );
}
