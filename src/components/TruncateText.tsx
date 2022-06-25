import Tooltip from '@mui/material/Tooltip';
import React from 'react';
import { styled, Typography } from '@mui/material';
export const EllipseText = styled(Typography)`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
`;

export default function TruncateText({ text }) {
    return (
        <Tooltip title={text}>
            <EllipseText variant="body2">{text}</EllipseText>
        </Tooltip>
    );
}
