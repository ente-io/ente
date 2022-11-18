import React, { useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import {
    changeFileName,
    splitFilenameAndExtension,
    updateExistingFilePubMetadata,
} from 'utils/file';
import EditIcon from '@mui/icons-material/Edit';
import { FlexWrapper, FreeFlowText, Value } from 'components/Container';
import { logError } from 'utils/sentry';
import { FileNameEditForm } from './FileNameEditForm';
import { IconButton } from '@mui/material';
import { FILE_TYPE } from 'constants/file';
import { PhotoOutlined, VideoFileOutlined } from '@mui/icons-material';

export const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + '.' + extension;
    } else {
        return filename;
    }
};

export function RenderFileName({
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}) {
    const originalTitle = file?.metadata.title;
    const [isInEditMode, setIsInEditMode] = useState(false);
    const [originalFileName, extension] =
        splitFilenameAndExtension(originalTitle);
    const [filename, setFilename] = useState(originalFileName);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const saveEdits = async (newFilename: string) => {
        try {
            if (file) {
                if (filename === newFilename) {
                    closeEditMode();
                    return;
                }
                setFilename(newFilename);
                const newTitle = getFileTitle(newFilename, extension);
                let updatedFile = await changeFileName(file, newTitle);
                updatedFile = (
                    await updateFilePublicMagicMetadata([updatedFile])
                )[0];
                updateExistingFilePubMetadata(file, updatedFile);
                scheduleUpdate();
            }
        } catch (e) {
            logError(e, 'failed to update file name');
        } finally {
            closeEditMode();
        }
    };
    return (
        <FlexWrapper>
            {file.metadata.fileType === FILE_TYPE.IMAGE ? (
                <PhotoOutlined />
            ) : (
                <VideoFileOutlined />
            )}
            {!isInEditMode ? (
                <>
                    <Value width={!shouldDisableEdits ? '60%' : '70%'}>
                        <FreeFlowText>
                            {getFileTitle(filename, extension)}
                        </FreeFlowText>
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
                <FileNameEditForm
                    extension={extension}
                    filename={filename}
                    saveEdits={saveEdits}
                    discardEdits={closeEditMode}
                />
            )}
        </FlexWrapper>
    );
}
