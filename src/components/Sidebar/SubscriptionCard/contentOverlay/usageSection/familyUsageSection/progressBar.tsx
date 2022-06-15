import { Box } from '@mui/material';
import React from 'react';
import { Progressbar } from '../../../styledComponents';
export function FamilyUsageProgressBar({ totalUsage, userDetails }) {
    return (
        <Box position={'relative'} width="100%">
            <Progressbar
                sx={{ backgroundColor: 'transparent' }}
                value={
                    (userDetails.usage * 100) / userDetails.familyData.storage
                }
            />
            <Progressbar
                sx={{
                    position: 'absolute',
                    top: 0,
                    zIndex: 1,
                    '.MuiLinearProgress-bar ': {
                        backgroundColor: 'text.secondary',
                    },
                    width: '100%',
                }}
                value={(totalUsage * 100) / userDetails.familyData.storage}
            />
        </Box>
    );
}
