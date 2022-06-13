import Tooltip from '@mui/material/Tooltip';
import React from 'react';
import styled from 'styled-components';

export const EllipseText = styled.div`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
`;

export default function TruncateText({ text }) {
    return (
        <Tooltip title={text}>
            <EllipseText>{text}</EllipseText>
        </Tooltip>
    );
}
