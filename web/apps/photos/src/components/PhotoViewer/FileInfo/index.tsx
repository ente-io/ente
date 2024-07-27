import { EnteDrawer } from "@/base/components/EnteDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { nameAndExtension } from "@/base/file";
import { FileType } from "@/media/file-type";
import type { ParsedMetadata } from "@/media/types/file";
import { UnidentifiedFaces } from "@/new/photos/components/PeopleList";
import type { RawExifTags } from "@/new/photos/services/exif";
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
import {
    Box,
    DialogProps,
    Link,
    Stack,
    styled,
    Typography,
} from "@mui/material";
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
    tags: RawExifTags | undefined;
    parsed: ParsedMetadata | undefined;
}

interface FileInfoProps {
    showInfo: boolean;
    handleCloseInfo: () => void;
    closePhotoViewer: () => void;
    file: EnteFile | undefined;
    exif: FileInfoExif | undefined;
    shouldDisableEdits?: boolean;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
    fileToCollectionsMap?: Map<number, number[]>;
    collectionNameMap?: Map<number, string>;
    showCollectionChips: boolean;
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

    const [exifInfo, setExifInfo] = useState<ExifInfo | undefined>();
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
        return exif?.parsed?.location;
    }, [file, exif]);

    useEffect(() => {
        setExifInfo(parseExifInfo(exif));
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
                        exifInfo: exifInfo,
                        shouldDisableEdits,
                        scheduleUpdate,
                    }}
                />

                {exifInfo?.takenOnDevice && (
                    <InfoItem
                        icon={<CameraOutlined />}
                        title={exifInfo?.takenOnDevice}
                        caption={
                            <BasicDeviceCamera {...{ parsedExif: exifInfo }} />
                        }
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
                        !exif ? (
                            <EnteSpinner size={12} />
                        ) : !exif.tags ? (
                            t("no_exif")
                        ) : (
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

            <RawExif
                open={openRawExif}
                onClose={() => setOpenRawExif(false)}
                onInfoClose={handleCloseInfo}
                tags={exif?.tags}
                fileName={file.metadata.title}
            />
        </FileInfoSidebar>
    );
};

/**
 * Some immediate fields of interest, in the form that we want to display on the
 * info panel for a file.
 */
type ExifInfo = Required<FileInfoExif> & {
    resolution?: string;
    megaPixels?: string;
    takenOnDevice?: string;
    fNumber?: string;
    exposureTime?: string;
    iso?: string;
};

const parseExifInfo = (
    fileInfoExif: FileInfoExif | undefined,
): ExifInfo | undefined => {
    if (!fileInfoExif || !fileInfoExif.tags || !fileInfoExif.parsed)
        return undefined;

    const info: ExifInfo = { ...fileInfoExif };

    const { width, height } = fileInfoExif.parsed;
    if (width && height) {
        info.resolution = `${width} x ${height}`;
        const mp = Math.round((width * height) / 1000000);
        if (mp) info.megaPixels = `${mp}MP`;
    }

    const { tags } = fileInfoExif;
    const { exif } = tags;

    if (exif) {
        if (exif.Make && exif.Model) {
            info["takenOnDevice"] =
                `${exif.Make.description} ${exif.Model.description}`;
        }

        if (exif.FNumber) {
            info.fNumber = `f/${Math.ceil(exif.FNumber.value)}`;
        } else if (exif.FocalLength && exif.ApertureValue) {
            info.fNumber = `f/${Math.ceil(
                exif.FocalLength.value / exif.ApertureValue.value,
            )}`;
        }

        if (exif.ExposureTime) {
            info["exposureTime"] = `1/${1 / exif.ExposureTime.value}`;
        }

        if (exif.ISOSpeedRatings) {
            const iso = exif.ISOSpeedRatings;
            const n = Array.isArray(iso) ? (iso[0] ?? 0) / (iso[1] ?? 1) : iso;
            info.iso = `ISO${n}`;
        }
    }
    return info;
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
    file: EnteFile;
    shouldDisableEdits: boolean;
    exifInfo: ExifInfo | undefined;
    scheduleUpdate: () => void;
}

const RenderFileName: React.FC<RenderFileNameProps> = ({
    file,
    shouldDisableEdits,
    exifInfo,
    scheduleUpdate,
}) => {
    const [isInEditMode, setIsInEditMode] = useState(false);
    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);
    const [fileName, setFileName] = useState<string>();
    const [extension, setExtension] = useState<string>();

    useEffect(() => {
        const [filename, extension] = nameAndExtension(file.metadata.title);
        setFileName(filename);
        setExtension(extension);
    }, [file]);

    const saveEdits = async (newFilename: string) => {
        if (!file) return;
        if (fileName === newFilename) {
            closeEditMode();
            return;
        }
        setFileName(newFilename);
        const newTitle = [newFilename, extension].join(".");
        const updatedFile = await changeFileName(file, newTitle);
        updateExistingFilePubMetadata(file, updatedFile);
        scheduleUpdate();
    };

    return (
        <>
            <InfoItem
                icon={
                    file.metadata.fileType === FileType.video ? (
                        <VideocamOutlined />
                    ) : (
                        <PhotoOutlined />
                    )
                }
                title={[fileName, extension].join(".")}
                caption={getCaption(file, exifInfo)}
                openEditor={openEditMode}
                hideEditOption={shouldDisableEdits || isInEditMode}
            />
            <FileNameEditDialog
                isInEditMode={isInEditMode}
                closeEditMode={closeEditMode}
                filename={fileName}
                extension={extension}
                saveEdits={saveEdits}
            />
        </>
    );
};

const getCaption = (file: EnteFile, exifInfo: ExifInfo | undefined) => {
    const megaPixels = exifInfo?.megaPixels;
    const resolution = exifInfo?.resolution;
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

const BasicDeviceCamera: React.FC<{ parsedExif: ExifInfo }> = ({
    parsedExif,
}) => {
    return (
        <FlexWrapper gap={1}>
            <Box>{parsedExif.fNumber}</Box>
            <Box>{parsedExif.exposureTime}</Box>
            <Box>{parsedExif.iso}</Box>
        </FlexWrapper>
    );
};

const getOpenStreetMapLink = (location: {
    latitude: number;
    longitude: number;
}) =>
    `https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}#map=15/${location.latitude}/${location.longitude}`;

interface RawExifProps {
    open: boolean;
    onClose: () => void;
    onInfoClose: () => void;
    tags: RawExifTags | undefined;
    fileName: string;
}

const RawExif: React.FC<RawExifProps> = ({
    open,
    onClose,
    onInfoClose,
    tags,
    fileName,
}) => {
    if (!tags) {
        return <></>;
    }

    const handleRootClose = () => {
        onClose();
        onInfoClose();
    };

    const items: (readonly [string, string, string, string])[] = Object.entries(
        tags,
    )
        .map(([namespace, namespaceTags]) => {
            return Object.entries(namespaceTags).map(([tagName, tag]) => {
                const key = `${namespace}:${tagName}`;
                let description = "<...>";
                if (typeof tag == "string") {
                    description = tag;
                } else if (typeof tag == "number") {
                    description = `${tag}`;
                } else if (
                    tag &&
                    typeof tag == "object" &&
                    "description" in tag
                ) {
                    description = tag.description;
                }
                return [key, namespace, tagName, description] as const;
            });
        })
        .flat()
        .filter(([, , , description]) => description);

    return (
        <FileInfoSidebar open={open} onClose={onClose}>
            <Titlebar
                onClose={onClose}
                title={t("exif")}
                caption={fileName}
                onRootClose={handleRootClose}
                actionButton={
                    <CopyButton
                        code={JSON.stringify(tags)}
                        color={"secondary"}
                    />
                }
            />
            <Stack py={3} px={1} spacing={2}>
                {items.map(([key, namespace, tagName, description]) => (
                    <ExifItem key={key}>
                        <Stack direction={"row"} gap={1}>
                            <Typography variant="small" color={"text.muted"}>
                                {tagName}
                            </Typography>
                            <Typography variant="tiny" color={"text.faint"}>
                                {namespace}
                            </Typography>
                        </Stack>
                        <Typography
                            sx={{
                                width: "100%",
                                textOverflow: "ellipsis",
                                whiteSpace: "nowrap",
                                overflow: "hidden",
                            }}
                        >
                            {description}
                        </Typography>
                    </ExifItem>
                ))}
            </Stack>
        </FileInfoSidebar>
    );
};

const ExifItem = styled(Box)`
    padding-left: 8px;
    padding-right: 8px;
    display: flex;
    flex-direction: column;
    gap: 4px;
`;
