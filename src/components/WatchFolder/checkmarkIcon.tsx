import React from 'react';
import CheckIcon from '@mui/icons-material/Check';

export function CheckmarkIcon() {
    return (
        <CheckIcon
            sx={{
                marginRight: '8px',
                color: (theme) => theme.palette.secondary.main,
            }}
        />
    );
}
