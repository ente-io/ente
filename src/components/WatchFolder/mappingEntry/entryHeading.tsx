import React, { useContext } from 'react';
import { Typography } from '@mui/material';
import watchFolderService from 'services/watchFolder/watchFolderService';
import { AppContext } from 'pages/_app';
import { SyncProgressIcon } from './syncProgressIcon';
import { FlexWrapper } from 'components/Container';
import { WatchMapping } from 'types/watchFolder';

interface Iprops {
    mapping: WatchMapping;
}

export function EntryHeading({ mapping }: Iprops) {
    const appContext = useContext(AppContext);
    return (
        <FlexWrapper gap={0.5}>
            <Typography>{mapping.rootFolderName}</Typography>
            {appContext.isFolderSyncRunning &&
                watchFolderService.isMappingSyncing(mapping) && (
                    <SyncProgressIcon />
                )}
        </FlexWrapper>
    );
}
