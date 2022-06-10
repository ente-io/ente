import React, { useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import constants from 'utils/strings/constants';
import {
    changeFileCreationTime,
    formatDateTime,
    updateExistingFilePubMetadata,
} from 'utils/file';
import EditIcon from 'components/icons/EditIcon';
import { IconButton, Label, Row, Value } from 'components/Container';
import { logError } from 'utils/sentry';
import CloseIcon from '@mui/icons-material/Close';
import TickIcon from '@mui/icons-material/Done';
import EnteDateTimePicker from 'components/EnteDateTimePicker';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';

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

    const [pickedTime, setPickedTime] = useState(originalCreationTime);

    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const saveEdits = async () => {
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
    const discardEdits = () => {
        setPickedTime(originalCreationTime);
        closeEditMode();
    };
    const handleChange = (newDate: Date) => {
        if (newDate instanceof Date) {
            setPickedTime(newDate);
        }
    };
    return (
        <>
            <Row>
                <Label width="30%">{constants.CREATION_TIME}</Label>
                <Value
                    width={
                        !shouldDisableEdits
                            ? isInEditMode
                                ? '50%'
                                : '60%'
                            : '70%'
                    }>
                    {isInEditMode ? (
                        <EnteDateTimePicker
                            loading={loading}
                            isInEditMode={isInEditMode}
                            pickedTime={pickedTime}
                            handleChange={handleChange}
                        />
                    ) : (
                        formatDateTime(pickedTime)
                    )}
                </Value>
                {!shouldDisableEdits && (
                    <Value
                        width={isInEditMode ? '20%' : '10%'}
                        style={{ cursor: 'pointer', marginLeft: '10px' }}>
                        {!isInEditMode ? (
                            <IconButton onClick={openEditMode}>
                                <EditIcon />
                            </IconButton>
                        ) : (
                            <>
                                <IconButton onClick={saveEdits}>
                                    {loading ? (
                                        <SmallLoadingSpinner />
                                    ) : (
                                        <TickIcon />
                                    )}
                                </IconButton>
                                <IconButton onClick={discardEdits}>
                                    <CloseIcon />
                                </IconButton>
                            </>
                        )}
                    </Value>
                )}
            </Row>
        </>
    );
}
