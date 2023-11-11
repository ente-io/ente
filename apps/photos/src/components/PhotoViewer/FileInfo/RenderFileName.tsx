import React, { useEffect, useState } from 'react';
import { EnteFile } from 'types/file';
import {
    changeFileName,
    splitFilenameAndExtension,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { FlexWrapper } from '@ente/shared/components/Container';
import { logError } from '@ente/shared/sentry';
import { FILE_TYPE } from 'constants/file';
import InfoItem from './InfoItem';
import { makeHumanReadableStorage } from 'utils/billing';
import Box from '@mui/material/Box';
import { FileNameEditDialog } from './FileNameEditDialog';
import VideocamOutlined from '@mui/icons-material/VideocamOutlined';
import PhotoOutlined from '@mui/icons-material/PhotoOutlined';

const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + '.' + extension;
    } else {
        return filename;
    }
};

const getCaption = (file: EnteFile, parsedExifData) => {
    const megaPixels = parsedExifData?.['megaPixels'];
    const resolution = parsedExifData?.['resolution'];
    const fileSize = file.info?.fileSize;

    const captionParts = [];
    if (megaPixels) {
        captionParts.push(megaPixels);
    }
    if (resolution) {
        captionParts.push(resolution);
    }
    if (fileSize) {
        captionParts.push(makeHumanReadableStorage(fileSize));
    }
    return (
        <FlexWrapper gap={1}>
            {captionParts.map((caption) => (
                <Box key={caption}> {caption}</Box>
            ))}
        </FlexWrapper>
    );
};

export function RenderFileName({
    parsedExifData,
    shouldDisableEdits,
    file,
    scheduleUpdate,
}: {
    parsedExifData: Record<string, any>;
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}) {
    const [isInEditMode, setIsInEditMode] = useState(false);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);
    const [filename, setFilename] = useState<string>();
    const [extension, setExtension] = useState<string>();

    useEffect(() => {
        const [filename, extension] = splitFilenameAndExtension(
            file.metadata.title
        );
        setFilename(filename);
        setExtension(extension);
    }, [file]);

    const saveEdits = async (newFilename: string) => {
        try {
            if (file) {
                if (filename === newFilename) {
                    closeEditMode();
                    return;
                }
                setFilename(newFilename);
                const newTitle = getFileTitle(newFilename, extension);
                const updatedFile = await changeFileName(file, newTitle);
                updateExistingFilePubMetadata(file, updatedFile);
                scheduleUpdate();
            }
        } catch (e) {
            logError(e, 'failed to update file name');
            throw e;
        }
    };

    return (
        <>
            <InfoItem
                icon={
                    file.metadata.fileType === FILE_TYPE.VIDEO ? (
                        <VideocamOutlined />
                    ) : (
                        <PhotoOutlined />
                    )
                }
                title={getFileTitle(filename, extension)}
                caption={getCaption(file, parsedExifData)}
                openEditor={openEditMode}
                hideEditOption={shouldDisableEdits || isInEditMode}
            />
            <FileNameEditDialog
                isInEditMode={isInEditMode}
                closeEditMode={closeEditMode}
                filename={filename}
                extension={extension}
                saveEdits={saveEdits}
            />
        </>
    );
}
