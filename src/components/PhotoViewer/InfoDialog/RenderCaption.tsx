import React, { useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import constants from 'utils/strings/constants';
import { changeCaption, updateExistingFilePubMetadata } from 'utils/file';
import EditIcon from '@mui/icons-material/Edit';
import { FreeFlowText, Label, Row, Value } from 'components/Container';
import { logError } from 'utils/sentry';
import { IconButton, Typography } from '@mui/material';
import { CaptionEditForm } from './CaptionEditForm';

export const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + '.' + extension;
    } else {
        return filename;
    }
};

export function RenderCaption({
    shouldDisableEdits,
    file,
    scheduleUpdate,
    refreshPhotoswipe,
}: {
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
}) {
    const [caption, setCaption] = useState(
        file?.pubMagicMetadata?.data.caption
    );
    const [isInEditMode, setIsInEditMode] = useState(false);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const saveEdits = async (newCaption: string) => {
        try {
            if (file) {
                if (caption === newCaption) {
                    closeEditMode();
                    return;
                }
                setCaption(newCaption);

                let updatedFile = await changeCaption(file, newCaption);
                updatedFile = (
                    await updateFilePublicMagicMetadata([updatedFile])
                )[0];
                updateExistingFilePubMetadata(file, updatedFile);
                file.title = file.pubMagicMetadata.data.caption;
                refreshPhotoswipe();
                scheduleUpdate();
            }
        } catch (e) {
            logError(e, 'failed to update caption');
        } finally {
            closeEditMode();
        }
    };
    return (
        <>
            <Row>
                <Label width="30%">{constants.CAPTION}</Label>
                {!isInEditMode ? (
                    <>
                        <Value width={!shouldDisableEdits ? '60%' : '70%'}>
                            {caption ? (
                                <FreeFlowText>{caption}</FreeFlowText>
                            ) : (
                                <Typography color="text.secondary">
                                    Add a caption
                                </Typography>
                            )}
                        </Value>
                        {!shouldDisableEdits && (
                            <Value
                                width="10%"
                                style={{
                                    cursor: 'pointer',
                                    marginLeft: '10px',
                                }}>
                                <IconButton onClick={openEditMode}>
                                    <EditIcon />
                                </IconButton>
                            </Value>
                        )}
                    </>
                ) : (
                    <CaptionEditForm
                        caption={caption}
                        saveEdits={saveEdits}
                        discardEdits={closeEditMode}
                    />
                )}
            </Row>
        </>
    );
}
