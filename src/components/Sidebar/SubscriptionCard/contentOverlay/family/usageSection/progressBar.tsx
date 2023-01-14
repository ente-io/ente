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
                value={Math.min((userUsage * 100) / totalStorage, 100)}
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
                value={Math.min((totalUsage * 100) / totalStorage, 100)}
            />
        </Box>
    );
}
