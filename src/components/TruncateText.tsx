import Tooltip from '@mui/material/Tooltip';
import React from 'react';
import { Box, styled, Typography } from '@mui/material';
export const EllipseText = styled(Typography)`
    /* white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis; */
    word-break: break-word;
`;

export default function TruncateText({ text }) {
    return (
        <Tooltip title={text}>
            <Box height={34} overflow="hidden">
                {/* todo add ellipsis */}
                <EllipseText variant="body2">{text}</EllipseText>
            </Box>
        </Tooltip>
    );
}
