import React, { useState } from 'react';
import { EnteFile } from 'types/file';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { formatDate, formatTime } from '@ente/shared/time/format';
import { FlexWrapper } from '@ente/shared/components/Container';
import { logError } from '@ente/shared/sentry';
import EnteDateTimePicker from 'components/EnteDateTimePicker';
import InfoItem from './InfoItem';

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
                const updatedFile = await changeFileCreationTime(
                    file,
                    unixTimeInMicroSec
                );
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
        <>
            <FlexWrapper>
                <InfoItem
                    icon={<CalendarTodayIcon />}
                    title={formatDate(originalCreationTime)}
                    caption={formatTime(originalCreationTime)}
                    openEditor={openEditMode}
                    loading={loading}
                    hideEditOption={shouldDisableEdits || isInEditMode}
                />
                {isInEditMode && (
                    <EnteDateTimePicker
                        initialValue={originalCreationTime}
                        disabled={loading}
                        onSubmit={saveEdits}
                        onClose={closeEditMode}
                    />
                )}
            </FlexWrapper>
        </>
    );
}
