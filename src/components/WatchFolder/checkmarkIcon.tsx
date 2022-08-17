import React from 'react';
import CheckIcon from '@mui/icons-material/Check';

export function CheckmarkIcon() {
    return (
        <CheckIcon
            sx={{
                mr: 1,
                color: (theme) => theme.palette.secondary.main,
            }}
        />
    );
}
