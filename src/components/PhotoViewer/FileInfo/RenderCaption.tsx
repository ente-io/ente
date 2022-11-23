import React, { useEffect, useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import { changeCaption, updateExistingFilePubMetadata } from 'utils/file';
import { logError } from 'utils/sentry';
import { Box } from '@mui/material';
import { CaptionEditForm } from './CaptionEditForm';

export const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + '.' + extension;
    } else {
        return filename;
    }
};

export function RenderCaption({
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
    const closeEditMode = () => {
        console.log('sss');
        setIsInEditMode(false);
    };

    useEffect(() => {
        console.log(isInEditMode);
    }, [isInEditMode]);
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
        <Box p={1}>
            <CaptionEditForm
                openEditMode={openEditMode}
                isInEditMode={isInEditMode}
                caption={caption}
                saveEdits={saveEdits}
                discardEdits={closeEditMode}
            />
        </Box>
    );
}
