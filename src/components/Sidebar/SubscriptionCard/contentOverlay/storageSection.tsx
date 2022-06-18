import { Box, Typography } from '@mui/material';
import React from 'react';
import { convertBytesToHumanReadable } from 'utils/billing';
import constants from 'utils/strings/constants';

interface Iprops {
    totalUsage: number;
    totalStorage: number;
}
export default function StorageSection({ totalUsage, totalStorage }: Iprops) {
    return (
        <Box width="100%">
            <Typography variant="body2" color={'text.secondary'}>
                {constants.STORAGE}
            </Typography>

            <Typography
                fontWeight={'bold'}
                sx={{ fontSize: '24px', lineHeight: '30px' }}>
                {`${convertBytesToHumanReadable(
                    totalStorage - totalUsage,
                    1
                )} ${constants.OF} ${convertBytesToHumanReadable(
                    totalStorage,
                    0
                )} ${constants.FREE}`}
            </Typography>
        </Box>
    );
}
