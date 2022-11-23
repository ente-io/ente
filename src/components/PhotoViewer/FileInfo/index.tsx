import React, { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { RenderFileName } from './RenderFileName';
// import { ExifData } from './ExifData';
import { RenderCreationTime } from './RenderCreationTime';
import { DialogProps, Drawer, Link, Stack, styled } from '@mui/material';
import { Location, Metadata } from 'types/upload';
import Photoswipe from 'photoswipe';
import { getEXIFLocation } from 'services/upload/exifService';
import { RenderCaption } from './RenderCaption';
import {
    BackupOutlined,
    FolderOutlined,
    LocationOnOutlined,
    TextSnippetOutlined,
} from '@mui/icons-material';
import CopyButton from 'components/CodeBlock/CopyButton';
import { formatDateTime } from 'utils/time';
import { Badge } from 'components/Badge';
import Titlebar from 'components/Titlebar';
import InfoItem from './InfoItem';

const FileInfoSidebar = styled((props: DialogProps) => (
    <Drawer {...props} anchor="right" />
))(({ theme }) => ({
    zIndex: 1501,
    '& .MuiPaper-root': {
        maxWidth: '375px',
        width: '100%',
        scrollbarWidth: 'thin',
        padding: theme.spacing(1),
    },
}));

interface Iprops {
    shouldDisableEdits: boolean;
    showInfo: boolean;
    handleCloseInfo: () => void;
    items: any[];
    photoSwipe: Photoswipe<Photoswipe.Options>;
    metadata: Metadata;
    exif: any;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
}

export function FileInfo({
    shouldDisableEdits,
    showInfo,
    handleCloseInfo,
    items,
    photoSwipe,
    metadata,
    exif,
    scheduleUpdate,
    refreshPhotoswipe,
}: Iprops) {
    const [location, setLocation] = useState<Location>(null);

    useEffect(() => {
        if (!location && metadata) {
            if (metadata.longitude || metadata.longitude === 0) {
                setLocation({
                    latitude: metadata.latitude,
                    longitude: metadata.longitude,
                });
            }
        }
    }, [metadata]);

    useEffect(() => {
        if (!location && exif) {
            const exifLocation = getEXIFLocation(exif);
            if (exifLocation.latitude || exifLocation.latitude === 0) {
                setLocation(exifLocation);
            }
        }
    }, [exif]);

    if (!metadata) {
        return <></>;
    }

    return (
        <FileInfoSidebar open={showInfo} onClose={handleCloseInfo}>
            <Titlebar onClose={handleCloseInfo} title={constants.INFO} />
            <Stack pt={1} pb={3} spacing={'20px'}>
                <RenderCaption
                    shouldDisableEdits={shouldDisableEdits}
                    file={items[photoSwipe?.getCurrentIndex()]}
                    scheduleUpdate={scheduleUpdate}
                    refreshPhotoswipe={refreshPhotoswipe}
                />

                <RenderCreationTime
                    shouldDisableEdits={shouldDisableEdits}
                    file={items[photoSwipe?.getCurrentIndex()]}
                    scheduleUpdate={scheduleUpdate}
                />

                <RenderFileName
                    shouldDisableEdits={shouldDisableEdits}
                    file={items[photoSwipe?.getCurrentIndex()]}
                    scheduleUpdate={scheduleUpdate}
                />

                {location && (
                    <InfoItem
                        icon={<LocationOnOutlined />}
                        title={constants.LOCATION}
                        caption={
                            <Link
                                href={`https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}`}>
                                {constants.SHOW_ON_MAP}
                            </Link>
                        }
                        customEndButton={
                            <CopyButton
                                code={`https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}`}
                                color="secondary"
                                size="medium"
                            />
                        }
                    />
                )}
                <InfoItem
                    icon={<TextSnippetOutlined />}
                    title={constants.DETAILS}
                    caption={constants.VIEW_EXIF}
                    hideEditOption
                />
                <InfoItem
                    icon={<BackupOutlined />}
                    title={formatDateTime(metadata.modificationTime / 1000)}
                    caption={formatDateTime(metadata.modificationTime / 1000)}
                    hideEditOption
                />

                <InfoItem icon={<FolderOutlined />} hideEditOption>
                    <Stack spacing={1} direction="row">
                        <Badge>abc</Badge>
                        <Badge>DEF</Badge>
                        <Badge>GHI</Badge>
                    </Stack>
                </InfoItem>

                {/* {exif && (
                    <>
                        <ExifData exif={exif} />
                    </>
                )} */}
            </Stack>
        </FileInfoSidebar>
    );
}
