import Tooltip from '@mui/material/Tooltip';
import React from 'react';
import { Box, Typography } from '@mui/material';

export default function TruncateText({ text }) {
    return (
        <Tooltip title={text}>
            <Box height={34} overflow="hidden">
                {/* todo add ellipsis */}
                <Typography variant="body2" sx={{ wordBreak: 'break-word' }}>
                    {text}
                </Typography>
            </Box>
        </Tooltip>
    );
}
