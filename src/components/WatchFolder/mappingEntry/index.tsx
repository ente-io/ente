import { EntryContainer } from '../styledComponents';
import React from 'react';
import { Typography } from '@mui/material';
import { HorizontalFlex, SpaceBetweenFlex } from 'components/Container';
import { WatchMapping } from 'types/watchFolder';
import { AppContext } from 'pages/_app';
import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import constants from 'utils/strings/constants';
import MappingEntryOptions from './mappingEntryOptions';
import { EntryHeading } from './entryHeading';

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
            title: constants.STOP_WATCHING_FOLDER,
            content: constants.STOP_WATCHING_DIALOG_MESSAGE,
            close: {
                text: constants.CANCEL,
                variant: 'primary',
            },
            proceed: {
                action: stopWatching,
                text: constants.YES_STOP,
                variant: 'danger',
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <HorizontalFlex>
                <FolderOpenIcon />
                <EntryContainer>
                    <EntryHeading mapping={mapping} />
                    <Typography color="text.secondary" variant="body2">
                        {mapping.folderPath}
                    </Typography>
                </EntryContainer>
            </HorizontalFlex>
            <MappingEntryOptions confirmStopWatching={confirmStopWatching} />
        </SpaceBetweenFlex>
    );
}
