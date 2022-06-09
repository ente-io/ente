import { Box, Typography } from '@mui/material';
import React from 'react';
import { convertBytesToHumanReadable } from 'utils/billing';
import constants from 'utils/strings/constants';

export default function StorageSection({ userDetails }) {
    return (
        <Box padding={2}>
            <Typography variant="body2" color={'text.secondary'}>
                {constants.STORAGE}
            </Typography>

            <Typography
                fontWeight={'bold'}
                sx={{
                    fontSize: '24px',
                }}>
                {`${convertBytesToHumanReadable(
                    userDetails.usage,
                    1
                )} of ${convertBytesToHumanReadable(
                    userDetails.subscription.storage,
                    0
                )}`}
            </Typography>
        </Box>
    );
}
