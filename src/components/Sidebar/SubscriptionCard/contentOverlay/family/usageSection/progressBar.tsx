import { Box } from '@mui/material';
import React from 'react';
import { Progressbar } from '../../../styledComponents';
interface Iprops {
    userUsage: number;
    totalUsage: number;
    totalStorage: number;
}

export function FamilyUsageProgressBar({
    userUsage,
    totalUsage,
    totalStorage,
}: Iprops) {
    return (
        <Box position={'relative'} width="100%">
            <Progressbar
                sx={{ backgroundColor: 'transparent' }}
                value={(userUsage * 100) / totalStorage}
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
                value={(totalUsage * 100) / totalStorage}
            />
        </Box>
    );
}
