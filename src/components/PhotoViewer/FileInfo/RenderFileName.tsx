import React, { useState } from 'react';
import { updateFilePublicMagicMetadata } from 'services/fileService';
import { EnteFile } from 'types/file';
import {
    changeFileName,
    splitFilenameAndExtension,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { FlexWrapper } from 'components/Container';
import { logError } from 'utils/sentry';
import { FileNameEditForm } from './FileNameEditForm';
import { FILE_TYPE } from 'constants/file';
import { PhotoOutlined, VideoFileOutlined } from '@mui/icons-material';
import InfoItem from './InfoItem';
import { makeHumanReadableStorage } from 'utils/billing';

const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + '.' + extension;
    } else {
        return filename;
    }
};

const getCaption = (file: EnteFile, exif) => {
    const cameraMP = exif?.['megaPixels'];
    const resolution = exif?.['resolution'];
    const fileSize = file.info?.fileSize;

    const captionParts = [];
    if (cameraMP) {
        captionParts.push(`${cameraMP} MP`);
    }
    if (resolution) {
        captionParts.push(resolution);
    }
    if (fileSize) {
        captionParts.push(makeHumanReadableStorage(fileSize));
    }
    return captionParts.join(' ');
};

export function RenderFileName({
    exif,
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    exif: Record<string, any>;
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
            {!isInEditMode ? (
                <InfoItem
                    icon={
                        file.metadata.fileType === FILE_TYPE.IMAGE ? (
                            <PhotoOutlined />
                        ) : (
                            <VideoFileOutlined />
                        )
                    }
                    title={getFileTitle(filename, extension)}
                    caption={getCaption(file, exif)}
                    openEditor={openEditMode}
                    loading={false}
                    hideEditOption={shouldDisableEdits || isInEditMode}
                />
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
