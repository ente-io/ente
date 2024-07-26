import { EnteDrawer } from "@/base/components/EnteDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { nameAndExtension } from "@/base/file";
import log from "@/base/log";
import { FILE_TYPE } from "@/media/file-type";
import { UnidentifiedFaces } from "@/new/photos/components/PeopleList";
import type { ParsedExif, RawExifTags } from "@/new/photos/services/exif";
import { isMLEnabled } from "@/new/photos/services/ml";
import { EnteFile } from "@/new/photos/types/file";
import { formattedByteSize } from "@/new/photos/utils/units";
import CopyButton from "@ente/shared/components/CodeBlock/CopyButton";
import { FlexWrapper } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { formatDate, formatTime } from "@ente/shared/time/format";
import BackupOutlined from "@mui/icons-material/BackupOutlined";
import CameraOutlined from "@mui/icons-material/CameraOutlined";
import FolderOutlined from "@mui/icons-material/FolderOutlined";
import LocationOnOutlined from "@mui/icons-material/LocationOnOutlined";
import PhotoOutlined from "@mui/icons-material/PhotoOutlined";
import TextSnippetOutlined from "@mui/icons-material/TextSnippetOutlined";
import VideocamOutlined from "@mui/icons-material/VideocamOutlined";
import { Box, DialogProps, Link, Stack, styled } from "@mui/material";
import { Chip } from "components/Chip";
import LinkButton from "components/pages/gallery/LinkButton";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useMemo, useState } from "react";
import { changeFileName, updateExistingFilePubMetadata } from "utils/file";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import {
    getMapDisableConfirmationDialog,
    getMapEnableConfirmationDialog,
} from "utils/ui";
import { FileNameEditDialog } from "./FileNameEditDialog";
import InfoItem from "./InfoItem";
import MapBox from "./MapBox";
import { RenderCaption } from "./RenderCaption";
import { RenderCreationTime } from "./RenderCreationTime";

export interface FileInfoExif {
    tags: RawExifTags;
    parsed: ParsedExif;
}
interface FileInfoProps {
    shouldDisableEdits?: boolean;
    showInfo: boolean;
    handleCloseInfo: () => void;
    file: EnteFile;
    exif: FileInfoExif | undefined;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
    fileToCollectionsMap?: Map<number, number[]>;
    collectionNameMap?: Map<number, string>;
    showCollectionChips: boolean;
    closePhotoViewer: () => void;
}

export const FileInfo: React.FC<FileInfoProps> = ({
    shouldDisableEdits,
    showInfo,
    handleCloseInfo,
    file,
    exif,
    scheduleUpdate,
    refreshPhotoswipe,
    fileToCollectionsMap,
    collectionNameMap,
    showCollectionChips,
    closePhotoViewer,
}) => {
    const { mapEnabled, updateMapEnabled, setDialogBoxAttributesV2 } =
        useContext(AppContext);
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [parsedExif, setParsedExif] = useState<
        ParsedFileInfoExif | undefined
    >();
    const [openRawExif, setOpenRawExif] = useState(false);

    const location = useMemo(() => {
        if (file && file.metadata) {
            if (
                (file.metadata.latitude || file.metadata.latitude === 0) &&
                !(file.metadata.longitude === 0 && file.metadata.latitude === 0)
            ) {
                return {
                    latitude: file.metadata.latitude,
                    longitude: file.metadata.longitude,
                };
            }
        }
        return exif.parsed.location;
    }, [file]);

    useEffect(() => {
        setParsedExif(exif ? parseFileInfoExif(exif) : undefined);
    }, [exif]);

    if (!file) {
        return <></>;
    }

    const onCollectionChipClick = (collectionID) => {
        galleryContext.setActiveCollectionID(collectionID);
        galleryContext.setIsInSearchMode(false);
        closePhotoViewer();
    };

    const openEnableMapConfirmationDialog = () =>
        setDialogBoxAttributesV2(
            getMapEnableConfirmationDialog(() => updateMapEnabled(true)),
        );

    const openDisableMapConfirmationDialog = () =>
        setDialogBoxAttributesV2(
            getMapDisableConfirmationDialog(() => updateMapEnabled(false)),
        );

    return (
        <FileInfoSidebar open={showInfo} onClose={handleCloseInfo}>
            <Titlebar onClose={handleCloseInfo} title={t("INFO")} backIsClose />
            <Stack pt={1} pb={3} spacing={"20px"}>
                <RenderCaption
                    {...{
                        file,
                        shouldDisableEdits,
                        scheduleUpdate,
                        refreshPhotoswipe,
                    }}
                />

                <RenderCreationTime
                    {...{ file, shouldDisableEdits, scheduleUpdate }}
                />

                <RenderFileName
                    {...{
                        file,
                        parsedExif,
                        shouldDisableEdits,
                        scheduleUpdate,
                    }}
                />

                {parsedExif?.takenOnDevice && (
                    <InfoItem
                        icon={<CameraOutlined />}
                        title={parsedExif?.takenOnDevice}
                        caption={<BasicDeviceCamera {...{ parsedExif }} />}
                        hideEditOption
                    />
                )}

                {location && (
                    <>
                        <InfoItem
                            icon={<LocationOnOutlined />}
                            title={t("LOCATION")}
                            caption={
                                !mapEnabled ||
                                publicCollectionGalleryContext.accessedThroughSharedURL ? (
                                    <Link
                                        href={getOpenStreetMapLink(location)}
                                        target="_blank"
                                        sx={{ fontWeight: "bold" }}
                                    >
                                        {t("SHOW_ON_MAP")}
                                    </Link>
                                ) : (
                                    <LinkButton
                                        onClick={
                                            openDisableMapConfirmationDialog
                                        }
                                        sx={{
                                            textDecoration: "none",
                                            color: "text.muted",
                                            fontWeight: "bold",
                                        }}
                                    >
                                        {t("DISABLE_MAP")}
                                    </LinkButton>
                                )
                            }
                            customEndButton={
                                <CopyButton
                                    code={getOpenStreetMapLink(location)}
                                    color="secondary"
                                    size="medium"
                                />
                            }
                        />
                        {!publicCollectionGalleryContext.accessedThroughSharedURL && (
                            <MapBox
                                location={location}
                                mapEnabled={mapEnabled}
                                openUpdateMapConfirmationDialog={
                                    openEnableMapConfirmationDialog
                                }
                            />
                        )}
                    </>
                )}
                <InfoItem
                    icon={<TextSnippetOutlined />}
                    title={t("DETAILS")}
                    caption={
                        typeof exif === "undefined" ? (
                            <EnteSpinner size={11.33} />
                        ) : exif !== null ? (
                            <LinkButton
                                onClick={() => setOpenRawExif(true)}
                                sx={{
                                    textDecoration: "none",
                                    color: "text.muted",
                                    fontWeight: "bold",
                                }}
                            >
                                {t("view_exif")}
                            </LinkButton>
                        ) : (
                            t("no_exif")
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
                {showCollectionChips && (
                    <InfoItem icon={<FolderOutlined />} hideEditOption>
                        <Box
                            display={"flex"}
                            gap={1}
                            flexWrap="wrap"
                            justifyContent={"flex-start"}
                            alignItems={"flex-start"}
                        >
                            {fileToCollectionsMap
                                ?.get(file.id)
                                ?.filter((collectionID) =>
                                    collectionNameMap.has(collectionID),
                                )
                                ?.map((collectionID) => (
                                    <Chip
                                        key={collectionID}
                                        onClick={() =>
                                            onCollectionChipClick(collectionID)
                                        }
                                    >
                                        {collectionNameMap.get(collectionID)}
                                    </Chip>
                                ))}
                        </Box>
                    </InfoItem>
                )}

                {isMLEnabled() && (
                    <>
                        {/* <PhotoPeopleList file={file} /> */}
                        <UnidentifiedFaces enteFile={file} />
                    </>
                )}
            </Stack>
            <ExifData
                exif={exif.tags}
                open={openRawExif}
                onClose={() => setOpenRawExif(false)}
                onInfoClose={handleCloseInfo}
                filename={file.metadata.title}
            />
        </FileInfoSidebar>
    );
};

/**
 * Some immediate fields of interest, in the form that we want to display on the
 * info panel for a file.
 */
type ParsedFileInfoExif = FileInfoExif & {
    resolution?: string;
    megaPixels?: string;
    takenOnDevice?: string;
    fNumber?: string;
    exposureTime?: string;
    iso?: string;
};

const parseFileInfoExif = (fileInfoExif: FileInfoExif): ParsedFileInfoExif => {
    const parsed: ParsedFileInfoExif = { ...fileInfoExif };

    const { width, height } = fileInfoExif.parsed;
    if (width && height) {
        parsed.resolution = `${width} x ${height}`;
        const mp = Math.round((width * height) / 1000000);
        if (mp) parsed.megaPixels = `${mp}MP`;
    }

    const { tags } = fileInfoExif;
    const { exif } = tags;

    if (exif) {
        if (exif.Make && exif.Model) {
            parsed["takenOnDevice"] =
                `${exif.Make.description} ${exif.Model.description}`;
        }

        if (exif.FNumber) {
            parsed.fNumber = `f/${Math.ceil(exif.FNumber.value)}`;
        } else if (exif.FocalLength && exif.ApertureValue) {
            parsed.fNumber = `f/${Math.ceil(
                exif.FocalLength.value / exif.ApertureValue.value,
            )}`;
        }

        if (exif.ExposureTime) {
            parsed["exposureTime"] = `1/${1 / exif.ExposureTime.value}`;
        }

        if (exif.ISOSpeedRatings) {
            const iso = exif.ISOSpeedRatings;
            const n = Array.isArray(iso) ? (iso[0] ?? 0) / (iso[1] ?? 1) : iso;
            parsed.iso = `ISO${n}`;
        }
    }
    return parsed;
};

const FileInfoSidebar = styled((props: DialogProps) => (
    <EnteDrawer {...props} anchor="right" />
))({
    zIndex: 1501,
    "& .MuiPaper-root": {
        padding: 8,
    },
});

interface RenderFileNameProps {
    parsedExif: ParsedFileInfoExif;
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
}

const RenderFileName: React.FC<RenderFileNameProps> = ({
    parsedExif,
    shouldDisableEdits,
    file,
    scheduleUpdate,
}) => {
    const [isInEditMode, setIsInEditMode] = useState(false);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);
    const [filename, setFilename] = useState<string>();
    const [extension, setExtension] = useState<string>();

    useEffect(() => {
        const [filename, extension] = nameAndExtension(file.metadata.title);
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
            log.error("failed to update file name", e);
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
                caption={getCaption(file, parsedExif)}
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
};

const getFileTitle = (filename, extension) => {
    if (extension) {
        return filename + "." + extension;
    } else {
        return filename;
    }
};

const getCaption = (file: EnteFile, parsedExifData) => {
    const megaPixels = parsedExifData?.["megaPixels"];
    const resolution = parsedExifData?.["resolution"];
    const fileSize = file.info?.fileSize;

    const captionParts = [];
    if (megaPixels) {
        captionParts.push(megaPixels);
    }
    if (resolution) {
        captionParts.push(resolution);
    }
    if (fileSize) {
        captionParts.push(formattedByteSize(fileSize));
    }
    return (
        <FlexWrapper gap={1}>
            {captionParts.map((caption) => (
                <Box key={caption}> {caption}</Box>
            ))}
        </FlexWrapper>
    );
};

const BasicDeviceCamera: React.FC<{ parsedExif: ParsedFileInfoExif }> = ({
    parsedExif,
}) => {
    return (
        <FlexWrapper gap={1}>
            <Box>{parsedExif.fNumber}</Box>
            <Box>{parsedExif.exposureTime}</Box>
            <Box>{parsedExif.ISO}</Box>
        </FlexWrapper>
    );
};

function getOpenStreetMapLink(location: {
    latitude: number;
    longitude: number;
}) {
    return `https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=15/${location.latitude}/${location.longitude}`;
}

import { formatDateTimeFull } from "@ente/shared/time/format";
import { Typography } from "@mui/material";
import { FileInfoSidebar } from ".";

const ExifItem = styled(Box)`
    padding-left: 8px;
    padding-right: 8px;
    display: flex;
    flex-direction: column;
    gap: 4px;
`;

function parseExifValue(value: any) {
    switch (typeof value) {
        case "string":
        case "number":
            return value;
        default:
            if (value instanceof Date) {
                return formatDateTimeFull(value);
            }
            try {
                return JSON.stringify(Array.from(value));
            } catch (e) {
                return null;
            }
    }
}
export function ExifData(props: {
    exif: any;
    open: boolean;
    onClose: () => void;
    filename: string;
    onInfoClose: () => void;
}) {
    const { exif, open, onClose, filename, onInfoClose } = props;

    if (!exif) {
        return <></>;
    }
    const handleRootClose = () => {
        onClose();
        onInfoClose();
    };

    return (
        <FileInfoSidebar open={open} onClose={onClose}>
            <Titlebar
                onClose={onClose}
                title={t("exif")}
                caption={filename}
                onRootClose={handleRootClose}
                actionButton={
                    <CopyButton
                        code={JSON.stringify(exif)}
                        color={"secondary"}
                    />
                }
            />
            <Stack py={3} px={1} spacing={2}>
                {[...Object.entries(exif)]
                    .sort((a, b) => a[0].localeCompare(b[0]))
                    .map(([key, value]) =>
                        value ? (
                            <ExifItem key={key}>
                                <Typography
                                    variant="small"
                                    color={"text.muted"}
                                >
                                    {key}
                                </Typography>
                                <Typography
                                    sx={{
                                        width: "100%",
                                        textOverflow: "ellipsis",
                                        whiteSpace: "nowrap",
                                        overflow: "hidden",
                                    }}
                                >
                                    {parseExifValue(value)}
                                </Typography>
                            </ExifItem>
                        ) : (
                            <React.Fragment key={key}></React.Fragment>
                        ),
                    )}
            </Stack>
        </FileInfoSidebar>
    );
}
