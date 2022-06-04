import React from 'react';
import constants from 'utils/strings/constants';
import { formatDateTime } from 'utils/file';
import { RenderFileName } from './RenderFileName';
import { ExifData } from './ExifData';
import { RenderCreationTime } from './RenderCreationTime';
import { RenderInfoItem } from './RenderInfoItem';
import DialogBoxBase from 'components/DialogBox/base';
import DialogTitleWithCloseButton from 'components/DialogBox/titleWithCloseButton';
import { DialogContent, Link, Typography } from '@mui/material';

export function InfoModal({
    shouldDisableEdits,
    showInfo,
    handleCloseInfo,
    items,
    photoSwipe,
    metadata,
    exif,
    scheduleUpdate,
}) {
    return (
        <DialogBoxBase
            sx={{ zIndex: '1501' }}
            open={showInfo}
            onClose={handleCloseInfo}>
            <DialogTitleWithCloseButton onClose={handleCloseInfo}>
                {constants.INFO}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Typography variant="subtitle" mb={1}>
                    {constants.METADATA}
                </Typography>

                {RenderInfoItem(
                    constants.FILE_ID,
                    items[photoSwipe?.getCurrentIndex()]?.id
                )}
                {metadata?.title && (
                    <RenderFileName
                        shouldDisableEdits={shouldDisableEdits}
                        file={items[photoSwipe?.getCurrentIndex()]}
                        scheduleUpdate={scheduleUpdate}
                    />
                )}
                {metadata?.creationTime && (
                    <RenderCreationTime
                        shouldDisableEdits={shouldDisableEdits}
                        file={items[photoSwipe?.getCurrentIndex()]}
                        scheduleUpdate={scheduleUpdate}
                    />
                )}
                {metadata?.modificationTime &&
                    RenderInfoItem(
                        constants.UPDATED_ON,
                        formatDateTime(metadata.modificationTime / 1000)
                    )}
                {metadata?.longitude > 0 &&
                    metadata?.longitude > 0 &&
                    RenderInfoItem(
                        constants.LOCATION,
                        <Link
                            href={`https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}`}
                            target="_blank"
                            rel="noopener noreferrer">
                            {constants.SHOW_MAP}
                        </Link>
                    )}
                {exif && (
                    <>
                        <ExifData exif={exif} />
                    </>
                )}
            </DialogContent>
        </DialogBoxBase>
    );
}
