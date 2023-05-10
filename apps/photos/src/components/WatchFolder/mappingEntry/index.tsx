import { EntryContainer } from '../styledComponents';
import React from 'react';
import { Tooltip, Typography } from '@mui/material';
import { HorizontalFlex, SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import FolderCopyOutlinedIcon from '@mui/icons-material/FolderCopyOutlined';
import { t } from 'i18next';

import MappingEntryOptions from './mappingEntryOptions';
import { EntryHeading } from './entryHeading';
import { UPLOAD_STRATEGY } from 'constants/upload';

interface Iprops {
    mapping: WatchMapping;
    handleRemoveMapping: (mapping: WatchMapping) => void;
}

export function MappingEntry({ mapping, handleRemoveMapping }: Iprops) {
    const appContext = React.useContext(AppContext);

    const stopWatching = () => {
        handleRemoveMapping(mapping);
    };

    const confirmStopWatching = () => {
        appContext.setDialogMessage({
            title: t('STOP_WATCHING_FOLDER'),
            content: t('STOP_WATCHING_DIALOG_MESSAGE'),
            close: {
                text: t('CANCEL'),
                variant: 'secondary',
            },
            proceed: {
                action: stopWatching,
                text: t('YES_STOP'),
                variant: 'critical',
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <HorizontalFlex>
                {mapping &&
                mapping.uploadStrategy === UPLOAD_STRATEGY.SINGLE_COLLECTION ? (
                    <Tooltip title={t('UPLOADED_TO_SINGLE_COLLECTION')}>
                        <FolderOpenIcon />
                    </Tooltip>
                ) : (
                    <Tooltip title={t('UPLOADED_TO_SEPARATE_COLLECTIONS')}>
                        <FolderCopyOutlinedIcon />
                    </Tooltip>
                )}
                <EntryContainer>
                    <EntryHeading mapping={mapping} />
                    <Typography color="text.muted" variant="small">
                        {mapping.folderPath}
                    </Typography>
                </EntryContainer>
            </HorizontalFlex>
            <MappingEntryOptions confirmStopWatching={confirmStopWatching} />
        </SpaceBetweenFlex>
    );
}
