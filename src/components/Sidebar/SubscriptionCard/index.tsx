import { ClickIndicator } from './clickIndicator';
import { IndividualUsageSection } from './individualUsageSection';
import React, { useContext, useMemo } from 'react';
import { Box, Skeleton } from '@mui/material';
import { UserDetails } from 'types/user';

import StorageSection from './storageSection';
import { GalleryContext } from 'pages/gallery';
import { FamilyUsageSection } from './familyUsageSection';
import { hasNonAdminFamilyMembers, isPartOfFamily } from 'utils/billing';
interface Iprops {
    userDetails: UserDetails;
    closeSidebar: () => void;
}

export default function SubscriptionCard({ userDetails }: Iprops) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    if (!userDetails) {
        return (
            <Skeleton
                animation="wave"
                variant="rectangular"
                width={'100%'}
                height={148}
                sx={{ borderRadius: '8px' }}
            />
        );
    }

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
        <Box onClick={showPlanSelectorModal} sx={{ cursor: 'pointer' }}>
            <img
                style={{ position: 'absolute' }}
                src="/subscription-card-background.png"
            />
            <Box zIndex={1} position={'relative'} height={148}>
                <StorageSection
                    totalStorage={totalStorage}
                    totalUsage={totalUsage}
                />
                {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                    <FamilyUsageSection userDetails={userDetails} />
                ) : (
                    <IndividualUsageSection userDetails={userDetails} />
                )}
                <ClickIndicator />
            </Box>
        </Box>
    );
}
