import { IndividualUsageSection } from './individualUsageSection';
import React from 'react';
import { Box } from '@mui/material';
import { FamilyUsageSection } from './familyUsageSection';
import { hasNonAdminFamilyMembers } from 'utils/billing';

export function UsageSection({ userDetails }) {
    return (
        <Box width="100%" flexDirection="column" justifyContent={'center'}>
            {hasNonAdminFamilyMembers(userDetails.familyData) ? (
                <FamilyUsageSection userDetails={userDetails} />
            ) : (
                <IndividualUsageSection userDetails={userDetails} />
            )}
        </Box>
    );
}
