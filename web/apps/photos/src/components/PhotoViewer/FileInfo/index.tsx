import { EnteDrawer } from "@/base/components/EnteDrawer";
import type { MiniDialogAttributes } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Titlebar } from "@/base/components/Titlebar";
import { EllipsizedTypography } from "@/base/components/Typography";
import { useModalVisibility } from "@/base/components/utils/modal";
import { nameAndExtension } from "@/base/file";
import log from "@/base/log";
import type { Location } from "@/base/types";
import { EnteFile } from "@/media/file";
import type { ParsedMetadata } from "@/media/file-metadata";
import {
    fileCreationPhotoDate,
    fileLocation,
    updateRemotePublicMagicMetadata,
    type ParsedMetadataDate,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import { type ButtonishProps } from "@/new/photos/components/mui";
import { ChipButton } from "@/new/photos/components/mui/ChipButton";
import { FilePeopleList } from "@/new/photos/components/PeopleList";
import { PhotoDateTimePicker } from "@/new/photos/components/PhotoDateTimePicker";
import { fileInfoDrawerZIndex } from "@/new/photos/components/utils/z-index";
import { tagNumericValue, type RawExifTags } from "@/new/photos/services/exif";
import {
    getAnnotatedFacesForFile,
    isMLEnabled,
    type AnnotatedFaceID,
} from "@/new/photos/services/ml";
import { AppContext } from "@/new/photos/types/context";
import { formattedByteSize } from "@/new/photos/utils/units";
import CopyButton from "@ente/shared/components/CodeBlock/CopyButton";
import { FlexWrapper } from "@ente/shared/components/Container";
import { getPublicMagicMetadataSync } from "@ente/shared/file-metadata";
import { formatDate, formatTime } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import CameraOutlinedIcon from "@mui/icons-material/CameraOutlined";
import EditIcon from "@mui/icons-material/Edit";
import FaceRetouchingNaturalIcon from "@mui/icons-material/FaceRetouchingNatural";
import FolderOutlinedIcon from "@mui/icons-material/FolderOutlined";
import LocationOnOutlinedIcon from "@mui/icons-material/LocationOnOutlined";
import PhotoOutlinedIcon from "@mui/icons-material/PhotoOutlined";
import TextSnippetOutlinedIcon from "@mui/icons-material/TextSnippetOutlined";
import VideocamOutlinedIcon from "@mui/icons-material/VideocamOutlined";
import {
    Box,
    CircularProgress,
    DialogProps,
    IconButton,
    Link,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import LinkButton from "components/pages/gallery/LinkButton";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import React, { useContext, useEffect, useMemo, useState } from "react";
import { Trans } from "react-i18next";
import { changeFileName, updateExistingFilePubMetadata } from "utils/file";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
import { FileNameEditDialog } from "./FileNameEditDialog";
import MapBox from "./MapBox";
import { RenderCaption } from "./RenderCaption";

export interface FileInfoExif {
    tags: RawExifTags | undefined;
    parsed: ParsedMetadata | undefined;
}

export interface FileInfoProps {
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
    /**
     * Called when the user selects a person in the file info panel.
     */
    onSelectPerson?: ((personID: string) => void) | undefined;
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
    onSelectPerson,
}) => {
    const { mapEnabled, updateMapEnabled, showMiniDialog } =
        useContext(AppContext);
    const galleryContext = useContext(GalleryContext);
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );

    const [exifInfo, setExifInfo] = useState<ExifInfo | undefined>();
    const { show: showRawExif, props: rawExifVisibilityProps } =
        useModalVisibility();
    const [annotatedFaces, setAnnotatedFaces] = useState<AnnotatedFaceID[]>([]);

    const location = useMemo(() => {
        if (file) {
            const location = fileLocation(file);
            if (location) return location;
        }
        return exif?.parsed?.location;
    }, [file, exif]);

    useEffect(() => {
        if (!file) return;

        let didCancel = false;

        void (async () => {
            const result = await getAnnotatedFacesForFile(file);
            !didCancel && setAnnotatedFaces(result);
        })();

        return () => {
            didCancel = true;
        };
    }, [file]);

    useEffect(() => {
        setExifInfo(parseExifInfo(exif));
    }, [exif]);

    if (!file) {
        return <></>;
    }

    const onCollectionChipClick = (collectionID) => {
        galleryContext.onShowCollection(collectionID);
        closePhotoViewer();
    };

    const openEnableMapConfirmationDialog = () =>
        showMiniDialog(
            confirmEnableMapsDialogAttributes(() => updateMapEnabled(true)),
        );

    const openDisableMapConfirmationDialog = () =>
        showMiniDialog(
            confirmDisableMapsDialogAttributes(() => updateMapEnabled(false)),
        );

    const handleSelectFace = (annotatedFaceID: AnnotatedFaceID) => {
        if (onSelectPerson) {
            onSelectPerson(annotatedFaceID.personID);
            closePhotoViewer();
        }
    };

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

                <CreationTime
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
                        icon={<CameraOutlinedIcon />}
                        title={exifInfo?.takenOnDevice}
                        caption={
                            <BasicDeviceCamera {...{ parsedExif: exifInfo }} />
                        }
                    />
                )}

                {location && (
                    <>
                        <InfoItem
                            icon={<LocationOnOutlinedIcon />}
                            title={t("location")}
                            caption={
                                !mapEnabled ||
                                publicCollectionGalleryContext.accessedThroughSharedURL ? (
                                    <Link
                                        href={openStreetMapLink(location)}
                                        target="_blank"
                                        rel="noopener"
                                        sx={{ fontWeight: "bold" }}
                                    >
                                        {t("view_on_map")}
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
                                        {t("disable_map")}
                                    </LinkButton>
                                )
                            }
                            trailingButton={
                                <CopyButton
                                    code={openStreetMapLink(location)}
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
                    icon={<TextSnippetOutlinedIcon />}
                    title={t("DETAILS")}
                    caption={
                        !exif ? (
                            <ActivityIndicator size={12} />
                        ) : !exif.tags ? (
                            t("no_exif")
                        ) : (
                            <LinkButton
                                onClick={showRawExif}
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
                />
                {isMLEnabled() && annotatedFaces.length > 0 && (
                    <InfoItem icon={<FaceRetouchingNaturalIcon />}>
                        {/*t("UNIDENTIFIED_FACES")  TODO-Cluster remove */}
                        <FilePeopleList
                            file={file}
                            annotatedFaceIDs={annotatedFaces}
                            onSelectFace={handleSelectFace}
                        />
                    </InfoItem>
                )}
                {showCollectionChips && (
                    <InfoItem icon={<FolderOutlinedIcon />}>
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
                                    <ChipButton
                                        key={collectionID}
                                        onClick={() =>
                                            onCollectionChipClick(collectionID)
                                        }
                                    >
                                        {collectionNameMap.get(collectionID)}
                                    </ChipButton>
                                ))}
                        </Box>
                    </InfoItem>
                )}
            </Stack>

            <RawExif
                {...rawExifVisibilityProps}
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
        if (exif.Make && exif.Model)
            info["takenOnDevice"] =
                `${exif.Make.description} ${exif.Model.description}`;

        if (exif.FNumber)
            info.fNumber = exif.FNumber.description; /* e.g. "f/16" */

        if (exif.ExposureTime)
            info["exposureTime"] = exif.ExposureTime.description; /* "1/10" */

        if (exif.ISOSpeedRatings)
            info.iso = `ISO${tagNumericValue(exif.ISOSpeedRatings)}`;
    }
    return info;
};

const confirmEnableMapsDialogAttributes = (
    onConfirm: () => void,
): MiniDialogAttributes => ({
    title: t("enable_maps_confirm"),
    message: (
        <Trans
            i18nKey={"enable_maps_confirm_message"}
            components={{
                a: (
                    <Link
                        target="_blank"
                        rel="noopener"
                        href="https://www.openstreetmap.org/"
                    />
                ),
            }}
        />
    ),
    continue: { text: t("enable"), action: onConfirm },
});

const confirmDisableMapsDialogAttributes = (
    onConfirm: () => void,
): MiniDialogAttributes => ({
    title: t("disable_maps_confirm"),
    message: <Trans i18nKey={"disable_maps_confirm_message"} />,
    continue: { text: t("disable"), color: "critical", action: onConfirm },
});

const FileInfoSidebar = styled((props: DialogProps) => (
    <EnteDrawer {...props} anchor="right" />
))({
    zIndex: fileInfoDrawerZIndex,
    "& .MuiPaper-root": {
        padding: 8,
    },
});

interface InfoItemProps {
    /**
     * The icon associated with the info entry.
     */
    icon: React.ReactNode;
    /**
     * The primary content / title of the info entry.
     *
     * Only used if {@link children} are not specified.
     */
    title?: string;
    /**
     * The secondary information / subtext associated with the info entry.
     *
     * Only used if {@link children} are not specified.
     */
    caption?: React.ReactNode;
    /**
     * A component, usually a button (e.g. an "edit button"), shown at the
     * trailing edge of the info entry.
     */
    trailingButton?: React.ReactNode;
}

/**
 * An entry in the file info panel listing.
 */
const InfoItem: React.FC<React.PropsWithChildren<InfoItemProps>> = ({
    icon,
    title,
    caption,
    trailingButton,
    children,
}) => (
    <Box
        sx={{
            display: "flex",
            alignItems: "flex-start",
            flex: 1,
            gap: "12px",
        }}
    >
        <InfoItemIconContainer>{icon}</InfoItemIconContainer>
        <Box sx={{ flex: 1, mt: "4px" }}>
            {children ? (
                children
            ) : (
                <>
                    <Typography sx={{ wordBreak: "break-all" }}>
                        {title}
                    </Typography>
                    <Typography
                        variant="small"
                        color="text.muted"
                        {...(typeof caption == "string"
                            ? {}
                            : { component: "div" })}
                    >
                        {caption}
                    </Typography>
                </>
            )}
        </Box>
        {trailingButton}
    </Box>
);

const InfoItemIconContainer = styled("div")(
    ({ theme }) => `
    width: 48px;
    aspect-ratio: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: ${theme.colors.stroke.muted}
`,
);

type EditButtonProps = ButtonishProps & {
    /**
     * If true, then an activity indicator is shown in place of the edit icon.
     */
    loading?: boolean;
};

const EditButton: React.FC<EditButtonProps> = ({ onClick, loading }) => (
    <IconButton onClick={onClick} disabled={loading} color="secondary">
        {!loading ? (
            <EditIcon />
        ) : (
            <CircularProgress size={"24px"} color="inherit" />
        )}
    </IconButton>
);

interface CreationTimeProps {
    file: EnteFile;
    shouldDisableEdits: boolean;
    scheduleUpdate: () => void;
}

export const CreationTime: React.FC<CreationTimeProps> = ({
    file,
    shouldDisableEdits,
    scheduleUpdate,
}) => {
    const [loading, setLoading] = useState(false);
    const [isInEditMode, setIsInEditMode] = useState(false);

    const openEditMode = () => setIsInEditMode(true);
    const closeEditMode = () => setIsInEditMode(false);

    const publicMagicMetadata = getPublicMagicMetadataSync(file);
    const originalDate = fileCreationPhotoDate(file, publicMagicMetadata);

    const saveEdits = async (pickedTime: ParsedMetadataDate) => {
        try {
            setLoading(true);
            if (isInEditMode && file) {
                // [Note: Don't modify offsetTime when editing date via picker]
                //
                // Use the updated date time (both in its canonical dateTime
                // form, and also as in the epoch timestamp), but don't use the
                // offset.
                //
                // The offset here will be the offset of the computer where this
                // user is making this edit, not the offset of the place where
                // the photo was taken. In a future iteration of the date time
                // editor, we can provide functionality for the user to edit the
                // associated offset, but right now it is not even surfaced, so
                // don't also potentially overwrite it.
                const { dateTime, timestamp } = pickedTime;
                if (timestamp == originalDate.getTime()) {
                    // Same as before.
                    closeEditMode();
                    return;
                }

                await updateRemotePublicMagicMetadata(file, {
                    dateTime,
                    editedTime: timestamp,
                });

                scheduleUpdate();
            }
        } catch (e) {
            log.error("failed to update creationTime", e);
        } finally {
            closeEditMode();
            setLoading(false);
        }
    };

    return (
        <>
            <FlexWrapper>
                <InfoItem
                    icon={<CalendarTodayIcon />}
                    title={formatDate(originalDate)}
                    caption={formatTime(originalDate)}
                    trailingButton={
                        shouldDisableEdits || (
                            <EditButton
                                onClick={openEditMode}
                                loading={loading}
                            />
                        )
                    }
                />
                {isInEditMode && (
                    <PhotoDateTimePicker
                        initialValue={originalDate}
                        disabled={loading}
                        onAccept={saveEdits}
                        onClose={closeEditMode}
                    />
                )}
            </FlexWrapper>
        </>
    );
};

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
                        <VideocamOutlinedIcon />
                    ) : (
                        <PhotoOutlinedIcon />
                    )
                }
                title={[fileName, extension].join(".")}
                caption={getCaption(file, exifInfo)}
                trailingButton={
                    shouldDisableEdits || <EditButton onClick={openEditMode} />
                }
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

const openStreetMapLink = ({ latitude, longitude }: Location) =>
    `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=15/${latitude}/${longitude}`;

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
                    "description" in tag &&
                    typeof tag.description == "string"
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
                        <EllipsizedTypography
                            sx={{
                                width: "100%",
                            }}
                        >
                            {description}
                        </EllipsizedTypography>
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
