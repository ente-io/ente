import { Legend } from './legend';
import { FamilyUsageProgressBar } from './progressBar';
import { Box, Stack, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import constants from 'utils/strings/constants';

interface Iprops {
    userUsage: number;
    totalUsage: number;
    fileCount: number;
    totalStorage: number;
}

export function FamilyUsageSection({
    userUsage,
    totalUsage,
    fileCount,
    totalStorage,
}: Iprops) {
    return (
        <Box width="100%">
            <FamilyUsageProgressBar
                totalUsage={totalUsage}
                userUsage={userUsage}
                totalStorage={totalStorage}
            />
            <SpaceBetweenFlex
                sx={{
                    marginTop: 1.5,
                }}>
                <Stack direction={'row'} spacing={1.5}>
                    <Legend label={constants.YOU} color="text.primary" />
                    <Legend label={constants.FAMILY} color="text.secondary" />
                </Stack>
                <Typography variant="caption" fontWeight={'bold'}>
                    {constants.PHOTO_COUNT(fileCount ?? 0)}
                </Typography>
            </SpaceBetweenFlex>
        </Box>
    );
}
