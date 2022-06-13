import { Legend } from './legend';
import { FamilyUsageProgressBar } from './progressBar';
import { Stack, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React, { useMemo } from 'react';
import { UserDetails } from 'types/user';
import constants from 'utils/strings/constants';

export function FamilyUsageSection({
    userDetails,
}: {
    userDetails: UserDetails;
}) {
    const totalUsage = useMemo(
        () =>
            userDetails.familyData.members.reduce(
                (sum, currentMember) => sum + currentMember.usage,
                0
            ),
        [userDetails]
    );

    return (
        <>
            <FamilyUsageProgressBar
                totalUsage={totalUsage}
                userDetails={userDetails}
            />
            <SpaceBetweenFlex
                style={{
                    marginTop: '12px',
                }}>
                <Stack direction={'row'} spacing={'12px'}>
                    <Legend label={constants.YOU} color="text.primary" />
                    <Legend label={constants.FAMILY} color="text.secondary" />
                </Stack>
                <Typography variant="caption" fontWeight={'bold'}>
                    {constants.PHOTO_COUNT(userDetails.fileCount)}
                </Typography>
            </SpaceBetweenFlex>
        </>
    );
}
