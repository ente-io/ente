import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import Box from '@mui/material/Box';
import React from 'react';
export function ClickIndicator() {
    return (
        <Box position={'absolute'} top={64} right={0}>
            <ChevronRightIcon />
        </Box>
    );
}
