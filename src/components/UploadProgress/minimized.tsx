import { Snackbar, Paper } from '@mui/material';
import UploadProgressContext from 'contexts/uploadProgress';
import React, { useContext } from 'react';
import { UploadProgressHeader } from './header';
export function MinimizedUploadProgress(props) {
    const { open } = useContext(UploadProgressContext);
    return (
        <Snackbar
            open={!props.expanded && open}
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
