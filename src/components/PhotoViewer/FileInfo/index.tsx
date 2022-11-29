import React, { useEffect, useState } from 'react';
import constants from 'utils/strings/constants';
import { RenderFileName } from './RenderFileName';
import { RenderCreationTime } from './RenderCreationTime';
import { Box, DialogProps, Link, Stack, styled } from '@mui/material';
import { Location } from 'types/upload';
import { getEXIFLocation } from 'services/upload/exifService';
import { RenderCaption } from './RenderCaption';
import {
    BackupOutlined,
    CameraOutlined,
    FolderOutlined,
    LocationOnOutlined,
    TextSnippetOutlined,
} from '@mui/icons-material';
import CopyButton from 'components/CodeBlock/CopyButton';
import { formatDate, formatTime } from 'utils/time/format';
import Titlebar from 'components/Titlebar';
import InfoItem from './InfoItem';
import { FlexWrapper } from 'components/Container';
import EnteSpinner from 'components/EnteSpinner';
import { EnteFile } from 'types/file';
import { Chip } from 'components/Chip';
import LinkButton from 'components/pages/gallery/LinkButton';
import { ExifData } from './ExifData';
import { EnteDrawer } from 'components/EnteDrawer';

export const FileInfoSidebar = styled((props: DialogProps) => (
    <EnteDrawer {...props} anchor="right" />
))({
    zIndex: 1501,
    '& .MuiPaper-root': {
        padding: 8,
    },
});

interface Iprops {
    shouldDisableEdits: boolean;
    showInfo: boolean;
    handleCloseInfo: () => void;
    file: EnteFile;
    exif: any;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
    fileToCollectionsMap: Map<number, number[]>;
    collectionNameMap: Map<number, string>;
    isTrashCollection: boolean;
}

function BasicDeviceCamera({
    parsedExifData,
}: {
    parsedExifData: Record<string, any>;
}) {
    return (
        <FlexWrapper gap={1}>
            <Box>{parsedExifData['fNumber']}</Box>
            <Box>{parsedExifData['exposureTime']}</Box>
            <Box>{parsedExifData['ISO']}</Box>
        </FlexWrapper>
    );
}

function getOpenStreetMapLink(location: {
    latitude: number;
    longitude: number;
}) {
    return `https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=15/${location.latitude}/${location.longitude}`;
}

export function FileInfo({
    shouldDisableEdits,
    showInfo,
    handleCloseInfo,
    file,
    exif,
    scheduleUpdate,
    refreshPhotoswipe,
    fileToCollectionsMap,
    collectionNameMap,
    isTrashCollection,
}: Iprops) {
    const [location, setLocation] = useState<Location>(null);
    const [parsedExifData, setParsedExifData] = useState<Record<string, any>>();
    const [showExif, setShowExif] = useState(false);

    const openExif = () => setShowExif(true);
    const closeExif = () => setShowExif(false);

    useEffect(() => {
        if (!location && file && file.metadata) {
            if (file.metadata.longitude || file.metadata.longitude === 0) {
                setLocation({
                    latitude: file.metadata.latitude,
                    longitude: file.metadata.longitude,
                });
            }
        }
    }, [file]);

    useEffect(() => {
        if (!location && exif) {
            const exifLocation = getEXIFLocation(exif);
            if (exifLocation.latitude || exifLocation.latitude === 0) {
                setLocation(exifLocation);
            }
        }
    }, [exif]);

    useEffect(() => {
        if (!exif) {
            setParsedExifData({});
            return;
        }
        const parsedExifData = {};
        if (exif['fNumber']) {
            parsedExifData['fNumber'] = `f/${Math.ceil(exif['FNumber'])}`;
        } else if (exif['ApertureValue'] && exif['FocalLength']) {
            parsedExifData['fNumber'] = `f/${Math.ceil(
                exif['FocalLength'] / exif['ApertureValue']
            )}`;
        }
        const imageWidth = exif['ImageWidth'] ?? exif['ExifImageWidth'];
        const imageHeight = exif['ImageHeight'] ?? exif['ExifImageHeight'];
        if (imageWidth && imageHeight) {
            parsedExifData['resolution'] = `${imageWidth} x ${imageHeight}`;
            const megaPixels = Math.round((imageWidth * imageHeight) / 1000000);
            if (megaPixels) {
                parsedExifData['megaPixels'] = `${Math.round(
                    (imageWidth * imageHeight) / 1000000
                )}MP`;
            }
        }
        if (exif['Make'] && exif['Model']) {
            parsedExifData[
                'takenOnDevice'
            ] = `${exif['Make']} ${exif['Model']}`;
        }
        if (exif['ExposureTime']) {
            parsedExifData['exposureTime'] = `1/${
                1 / parseFloat(exif['ExposureTime'])
            }`;
        }
        if (exif['ISO']) {
            parsedExifData['ISO'] = `ISO${exif['ISO']}`;
        }
        setParsedExifData(parsedExifData);
    }, [exif]);

    if (!file) {
        return <></>;
    }

    return (
        <FileInfoSidebar open={showInfo} onClose={handleCloseInfo}>
            <Titlebar
                onClose={handleCloseInfo}
                title={constants.INFO}
                backIsClose
            />
            <Stack pt={1} pb={3} spacing={'20px'}>
                <RenderCaption
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                    refreshPhotoswipe={refreshPhotoswipe}
                />

                <RenderCreationTime
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                />

                <RenderFileName
                    parsedExifData={parsedExifData}
                    shouldDisableEdits={shouldDisableEdits}
                    file={file}
                    scheduleUpdate={scheduleUpdate}
                />
                {parsedExifData && parsedExifData['takenOnDevice'] && (
                    <InfoItem
                        icon={<CameraOutlined />}
                        title={parsedExifData['takenOnDevice']}
                        caption={
                            <BasicDeviceCamera
                                parsedExifData={parsedExifData}
                            />
                        }
                        hideEditOption
                    />
                )}

                {/* {location && ( */}
                <InfoItem
                    icon={<LocationOnOutlined />}
                    title={constants.LOCATION}
                    caption={
                        <Link
                            href={getOpenStreetMapLink({
                                latitude: file.metadata.latitude,
                                longitude: file.metadata.longitude,
                            })}
                            target="_blank"
                            sx={{ fontWeight: 'bold' }}>
                            {constants.SHOW_ON_MAP}
                        </Link>
                    }
                    customEndButton={
                        <CopyButton
                            code={getOpenStreetMapLink({
                                latitude: file.metadata.latitude,
                                longitude: file.metadata.longitude,
                            })}
                            color="secondary"
                            size="medium"
                        />
                    }
                />
                {/* )} */}
                <InfoItem
                    icon={<TextSnippetOutlined />}
                    title={constants.DETAILS}
                    caption={
                        typeof exif === 'undefined' ? (
                            <EnteSpinner size={11.33} />
                        ) : exif !== null ? (
                            <LinkButton
                                onClick={openExif}
                                sx={{
                                    textDecoration: 'none',
                                    color: 'text.secondary',
                                    fontWeight: 'bold',
                                }}>
                                {constants.VIEW_EXIF}
                            </LinkButton>
                        ) : (
                            constants.NO_EXIF
                        )
                    }
                    hideEditOption
                />
                <InfoItem
                    icon={<BackupOutlined />}
                    title={formatDate(file.metadata.modificationTime / 1000)}
                    caption={formatTime(file.metadata.modificationTime / 1000)}
                    hideEditOption
                />
                {!isTrashCollection && (
                    <InfoItem icon={<FolderOutlined />} hideEditOption>
                        <Box
                            display={'flex'}
                            gap={1}
                            flexWrap="wrap"
                            justifyContent={'flex-start'}
                            alignItems={'flex-start'}>
                            {fileToCollectionsMap
                                .get(file.id)
                                ?.filter((collectionID) =>
                                    collectionNameMap.has(collectionID)
                                )
                                ?.map((collectionID) => (
                                    <Chip key={collectionID}>
                                        {collectionNameMap.get(collectionID)}
                                    </Chip>
                                ))}
                        </Box>
                    </InfoItem>
                )}
            </Stack>
            <ExifData
                exif={exif}
                open={showExif}
                onClose={closeExif}
                onInfoClose={handleCloseInfo}
                filename={file.metadata.title}
            />
        </FileInfoSidebar>
    );
}
