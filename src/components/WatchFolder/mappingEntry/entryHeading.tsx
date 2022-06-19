import React, { useContext } from 'react';
import { Typography } from '@mui/material';
import watchService from 'services/watchFolderService';
import { AppContext } from 'pages/_app';
import { SyncProgressIcon } from './syncProgressIcon';

export function EntryHeading({ mapping }) {
    const appContext = useContext(AppContext);
    return (
        <Typography
            sx={{
                fontSize: '16px',
                lineHeight: '20px',
                marginBottom: '4px',
            }}>
            <>
                {mapping.collectionName}
                {appContext.isFolderSyncRunning &&
                    watchService.currentEvent?.collectionName ===
                        mapping.collectionName && <SyncProgressIcon />}
            </>
        </Typography>
    );
}
