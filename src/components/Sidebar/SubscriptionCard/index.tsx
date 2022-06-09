import { ClickIndicator } from './clickIndicator';
import { IndividualUsageSection } from './individualUsageSection';
import React, { useContext } from 'react';
import { Box, CircularProgress } from '@mui/material';
import Container from 'components/Container';
import { UserDetails } from 'types/user';

import StorageSection from './storageSection';
import { GalleryContext } from 'pages/gallery';
import { FamilyUsageSection } from './familyUsageSection';
import { hasNonAdminFamilyMembers } from 'utils/billing';
interface Iprops {
    userDetails: UserDetails;
    closeSidebar: () => void;
}

export default function SubscriptionCard({ userDetails }: Iprops) {
    const { showPlanSelectorModal } = useContext(GalleryContext);

    return (
        <Box
            display="flex"
            flexDirection={'column'}
            onClick={showPlanSelectorModal}
            sx={{ cursor: 'pointer' }}>
            <img
                style={{ position: 'absolute' }}
                src="/subscription-card-background.png"
            />
            {!userDetails ? (
                <Container>
                    <CircularProgress />
                </Container>
            ) : (
                <Box zIndex={1} position={'relative'} height={148}>
                    <StorageSection userDetails={userDetails} />
                    {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                        <FamilyUsageSection userDetails={userDetails} />
                    ) : (
                        <IndividualUsageSection userDetails={userDetails} />
                    )}
                    <ClickIndicator />
                </Box>
            )}
        </Box>
    );
}
