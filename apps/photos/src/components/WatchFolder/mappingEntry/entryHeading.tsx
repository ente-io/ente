import React, { useContext } from 'react';
import { CircularProgress, Typography } from '@mui/material';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { AppContext } from 'pages/_app';
import { FlexWrapper } from '@ente/shared/components/Container';
import { WatchMapping } from 'types/watchFolder';

interface Iprops {
    mapping: WatchMapping;
}

export function EntryHeading({ mapping }: Iprops) {
    const appContext = useContext(AppContext);
    return (
        <FlexWrapper gap={1}>
            <Typography>{mapping.rootFolderName}</Typography>
            {appContext.isFolderSyncRunning &&
                watchFolderService.isMappingSyncInProgress(mapping) && (
                    <CircularProgress size={12} />
                )}
        </FlexWrapper>
    );
}
