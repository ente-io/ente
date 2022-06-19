import React from 'react';
import { CircularProgress } from '@mui/material';

export function SyncProgressIcon() {
    return (
        <CircularProgress
            size={12}
            sx={{
                marginLeft: '6px',
            }}
        />
    );
}
