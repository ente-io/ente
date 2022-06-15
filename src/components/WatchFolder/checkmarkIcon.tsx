import React from 'react';
import { Icon } from '@mui/material';
import CheckIcon from '@mui/icons-material/Check';

export function CheckmarkIcon() {
    return (
        <Icon
            sx={{
                marginLeft: '4px',
                marginRight: '4px',
                color: (theme) => theme.palette.grey.A200,
            }}>
            <CheckIcon />
        </Icon>
    );
}
