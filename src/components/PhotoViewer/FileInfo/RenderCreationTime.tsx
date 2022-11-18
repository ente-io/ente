import React, { useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { formatDateTime } from 'utils/time';
import EditIcon from '@mui/icons-material/Edit';
import { FlexWrapper, Value } from 'components/Container';
import { logError } from 'utils/sentry';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';
import EnteDateTimePicker from 'components/EnteDateTimePicker';
import { IconButton } from '@mui/material';

export function RenderCreationTime({
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}) {
    const [loading, setLoading] = useState(false);
    const originalCreationTime = new Date(file?.metadata.creationTime / 1000);
    const [isInEditMode, setIsInEditMode] = useState(false);

    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const saveEdits = async (pickedTime: Date) => {
        try {
            setLoading(true);
            if (isInEditMode && file) {
                const unixTimeInMicroSec = pickedTime.getTime() * 1000;
                if (unixTimeInMicroSec === file?.metadata.creationTime) {
                    closeEditMode();
                    return;
                }
                let updatedFile = await changeFileCreationTime(
                    file,
                    unixTimeInMicroSec
                );
                updatedFile = (
                    await updateFilePublicMagicMetadata([updatedFile])
                )[0];
                updateExistingFilePubMetadata(file, updatedFile);
                scheduleUpdate();
            }
        } catch (e) {
            logError(e, 'failed to update creationTime');
        } finally {
            closeEditMode();
            setLoading(false);
        }
    };

    return (
        <FlexWrapper>
            <CalendarTodayIcon />
            <Value width={!shouldDisableEdits ? !isInEditMode && '60%' : '70%'}>
                {isInEditMode ? (
                    <EnteDateTimePicker
                        initialValue={originalCreationTime}
                        disabled={loading}
                        onSubmit={saveEdits}
                        onClose={closeEditMode}
                    />
                ) : (
                    formatDateTime(originalCreationTime)
                )}
            </Value>
            {!shouldDisableEdits && !isInEditMode && (
                <Value
                    width={'10%'}
                    style={{ cursor: 'pointer', marginLeft: '10px' }}>
                    {loading ? (
                        <IconButton>
                            <SmallLoadingSpinner />
                        </IconButton>
                    ) : (
                        <IconButton onClick={openEditMode}>
                            <EditIcon />
                        </IconButton>
                    )}
                </Value>
            )}
        </FlexWrapper>
    );
}
