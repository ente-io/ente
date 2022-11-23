import React, { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { RenderFileName } from './RenderFileName';
// import { ExifData } from './ExifData';
import { RenderCreationTime } from './RenderCreationTime';
import {
    Box,
    DialogProps,
    Drawer,
    IconButton,
    Link,
    Stack,
    styled,
    Typography,
} from '@mui/material';
import { Location, Metadata } from 'types/upload';
import Photoswipe from 'photoswipe';
import { getEXIFLocation } from 'services/upload/exifService';
import { RenderCaption } from './RenderCaption';
import CloseIcon from '@mui/icons-material/Close';
import {
    BackupOutlined,
    FolderOutlined,
    LocationOnOutlined,
    TextSnippetOutlined,
} from '@mui/icons-material';
import { FlexWrapper } from 'components/Container';
import CopyButton from 'components/CodeBlock/CopyButton';
import { formatDateShort, formatTime } from 'utils/time';
import { Badge } from 'components/Badge';

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
            <Box>
                <IconButton color="secondary" onClick={handleCloseInfo}>
                    <CloseIcon />
                </IconButton>
                <Typography variant="h3" fontWeight={'bold'} px={2} py={0.5}>
                    {constants.INFO}
                </Typography>
            </Box>
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

                {/* {location && ( */}
                <FlexWrapper sx={{ position: 'relative' }}>
                    <LocationOnOutlined />
                    <Box>
                        <Box>
                            <Typography>{constants.LOCATION}</Typography>
                        </Box>
                        <Link
                            href={`https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}`}
                            target="_blank"
                            rel="noopener noreferrer">
                            {constants.SHOW_ON_MAP}
                        </Link>
                    </Box>
                    <CopyButton
                        code={
                            'https://www.openstreetmap.org/?mlat=${metadata.latitude}&mlon=${metadata.longitude}#map=15/${metadata.latitude}/${metadata.longitude}'
                        }
                    />
                </FlexWrapper>
                <FlexWrapper>
                    <TextSnippetOutlined />
                    <Box>
                        <Box>{constants.DETAILS}</Box>
                        <Box>{constants.VIEW_EXIF}</Box>
                    </Box>
                </FlexWrapper>

                <FlexWrapper>
                    <BackupOutlined />
                    <Box>
                        <Box>
                            {formatDateShort(metadata.modificationTime / 1000)}
                        </Box>
                        <Box>{formatTime(metadata.modificationTime)}</Box>
                    </Box>
                </FlexWrapper>

                <FlexWrapper>
                    <FolderOutlined />
                    <Stack spacing={1} direction="row">
                        <Badge>abc</Badge>
                        <Badge>DEF</Badge>
                        <Badge>GHI</Badge>
                    </Stack>
                </FlexWrapper>
                {/* {exif && (
                    <>
                        <ExifData exif={exif} />
                    </>
                )} */}
            </Stack>
        </FileInfoSidebar>
    );
}
