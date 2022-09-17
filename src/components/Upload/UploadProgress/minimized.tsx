import { Snackbar, Paper } from '@mui/material';
import React from 'react';
import { UploadProgressHeader } from './header';
export function MinimizedUploadProgress() {
    return (
        <Snackbar
            open
            anchorOrigin={{
                horizontal: 'right',
                vertical: 'bottom',
            }}>
            <Paper
                sx={{
                    width: '360px',
                }}>
                <UploadProgressHeader />
            </Paper>
        </Snackbar>
    );
}
