/* eslint-disable @typescript-eslint/ban-ts-comment */
/* TODO: Audit this file
Plan of action:
- Move common components into FileInfoComponents.tsx

- Move the rest out to files in the apps themeselves: albums/SharedFileInfo
  and photos/FileInfo to deal with the @/new/photos imports here.
*/

import { LinkButtonUndecorated } from "@/base/components/LinkButton";
import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { type ButtonishProps } from "@/base/components/mui";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { Titlebar } from "@/base/components/Titlebar";
import { EllipsizedTypography } from "@/base/components/Typography";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import { haveWindow } from "@/base/env";
import { nameAndExtension } from "@/base/file-name";
import { formattedDate, formattedTime } from "@/base/i18n-date";
import log from "@/base/log";
import type { Location } from "@/base/types";
import { CopyButton } from "@/gallery/components/FileInfoComponents";
import { tagNumericValue, type RawExifTags } from "@/gallery/services/exif";
import {
    changeCaption,
    changeFileName,
    updateExistingFilePubMetadata,
} from "@/gallery/services/file";
import { formattedByteSize } from "@/gallery/utils/units";
import { type EnteFile } from "@/media/file";
import {
    fileCreationPhotoDate,
    fileLocation,
    filePublicMagicMetadata,
    updateRemotePublicMagicMetadata,
    type ParsedMetadata,
    type ParsedMetadataDate,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import { FileDateTimePicker } from "@/new/photos/components/FileDateTimePicker";
import { ChipButton } from "@/new/photos/components/mui/ChipButton";
import { FilePeopleList } from "@/new/photos/components/PeopleList";
import {
    confirmDisableMapsDialogAttributes,
    confirmEnableMapsDialogAttributes,
} from "@/new/photos/components/utils/dialog";
import { useSettingsSnapshot } from "@/new/photos/components/utils/use-snapshot";
import {
    aboveFileViewerContentZ,
    fileInfoDrawerZ,
} from "@/new/photos/components/utils/z-index";
import {
    getAnnotatedFacesForFile,
    isMLEnabled,
    type AnnotatedFaceID,
} from "@/new/photos/services/ml";
import { updateMapEnabled } from "@/new/photos/services/settings";
import { FlexWrapper } from "@ente/shared/components/Container";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import CameraOutlinedIcon from "@mui/icons-material/CameraOutlined";
import CloseIcon from "@mui/icons-material/Close";
import DoneIcon from "@mui/icons-material/Done";
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
    IconButton,
    Link,
    Stack,
    styled,
    TextField,
    Typography,
    type DialogProps,
} from "@mui/material";
import { Formik } from "formik";
import { t } from "i18next";
import React, { useEffect, useMemo, useRef, useState } from "react";
import * as Yup from "yup";

// Re-uses images from ~leaflet package.
import "leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css";
import "leaflet/dist/leaflet.css";
// eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-unused-expressions
haveWindow() && require("leaflet-defaulticon-compatibility");
const leaflet = haveWindow()
    ? // eslint-disable-next-line @typescript-eslint/no-require-imports
      (require("leaflet") as typeof import("leaflet"))
    : null;

/**
 * Exif data for a file, in a form suitable for use by {@link FileInfo}.
 *
 * TODO: Indicate missing exif (e.g. videos) better, both in the data type, and
 * in the UI (e.g. by omitting the entire row).
 */
export interface FileInfoExif {
    tags: RawExifTags | undefined;
    parsed: ParsedMetadata | undefined;
}

export type FileInfoProps = ModalVisibilityProps & {
    /**
     * The file whose information we are showing.
     */
    file: EnteFile | undefined;
    /**
     * Exif information for {@link file}.
     */
    exif: FileInfoExif | undefined;
    /**
     * If set, then controls to edit the file's metadata (name, date, caption)
     * will be shown.
     */
    allowEdits?: boolean;
    /**
     * If set, then an inline map will be shown (if the user has enabled it)
     * using the file's location.
     */
    allowMap?: boolean;
    /**
     * If set, then a clickable chip will be shown for each collection that this
     * file is a part of.
     *
     * Uses {@link fileCollectionIDs}, {@link allCollectionsNameByID} and
     * {@link onSelectCollection}, so all of those props should also be set for
     * this to have an effect.
     */
    showCollections?: boolean;
    /**
     * A map from file IDs to the IDs of the collections that they're a part of.
     *
     * Used when {@link showCollections} is set.
     */
    fileCollectionIDs?: Map<number, number[]>;
    /**
     * A map from collection IDs to their name.
     *
     * Used when {@link showCollections} is set.
     */
    allCollectionsNameByID?: Map<number, string>;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
    /**
     * Called when the user selects a collection from among the collections that
     * the file belongs to.
     */
    onSelectCollection?: (collectionID: number) => void;
    /**
     * Called when the user selects a person in the file info panel.
     */
    onSelectPerson?: (personID: string) => void;
};

export const FileInfo: React.FC<FileInfoProps> = ({
    open,
    onClose,
    file,
    exif,
    allowEdits,
    allowMap,
    showCollections,
    fileCollectionIDs,
    allCollectionsNameByID,
    scheduleUpdate,
    refreshPhotoswipe,
    onSelectCollection,
    onSelectPerson,
}) => {
    const { showMiniDialog } = useBaseContext();

    const { mapEnabled } = useSettingsSnapshot();

    const [annotatedFaces, setAnnotatedFaces] = useState<AnnotatedFaceID[]>([]);

    const { show: showRawExif, props: rawExifVisibilityProps } =
        useModalVisibility();

    const location = useMemo(
        // Prefer the location in the EnteFile, then fall back to Exif.
        () => (file ? fileLocation(file) : undefined) ?? exif?.parsed?.location,
        [file, exif],
    );

    const annotatedExif = useMemo(() => annotateExif(exif), [exif]);

    useEffect(() => {
        if (!file) return;

        let didCancel = false;

        void getAnnotatedFacesForFile(file).then(
            (faces) => !didCancel && setAnnotatedFaces(faces),
        );

        return () => {
            didCancel = true;
        };
    }, [file]);

    const openEnableMapConfirmationDialog = () =>
        showMiniDialog(
            confirmEnableMapsDialogAttributes(() => updateMapEnabled(true)),
        );

    const openDisableMapConfirmationDialog = () =>
        showMiniDialog(
            confirmDisableMapsDialogAttributes(() => updateMapEnabled(false)),
        );

    const handleSelectFace = ({ personID }: AnnotatedFaceID) =>
        onSelectPerson?.(personID);

    if (!file) {
        return <></>;
    }

    return (
        <FileInfoSidebar open={open} onClose={onClose}>
            <Titlebar onClose={onClose} title={t("info")} backIsClose />
            <Stack sx={{ pt: 1, pb: 3, gap: "20px" }}>
                <Caption
                    {...{
                        file,
                        allowEdits,
                        scheduleUpdate,
                        refreshPhotoswipe,
                    }}
                />
                <CreationTime {...{ file, allowEdits, scheduleUpdate }} />
                <FileName
                    {...{ file, annotatedExif, allowEdits, scheduleUpdate }}
                />

                {annotatedExif?.takenOnDevice && (
                    <InfoItem
                        icon={<CameraOutlinedIcon />}
                        title={annotatedExif.takenOnDevice}
                        caption={createMultipartCaption(
                            annotatedExif.fNumber,
                            annotatedExif.exposureTime,
                            annotatedExif.iso,
                        )}
                    />
                )}

                {location && (
                    <>
                        <InfoItem
                            icon={<LocationOnOutlinedIcon />}
                            title={t("location")}
                            caption={
                                !mapEnabled || !allowMap ? (
                                    <Link
                                        href={openStreetMapLink(location)}
                                        target="_blank"
                                        rel="noopener"
                                        sx={{ fontWeight: "medium" }}
                                    >
                                        {t("view_on_map")}
                                    </Link>
                                ) : (
                                    <LinkButtonUndecorated
                                        onClick={
                                            openDisableMapConfirmationDialog
                                        }
                                    >
                                        {t("disable_map")}
                                    </LinkButtonUndecorated>
                                )
                            }
                            trailingButton={
                                <CopyButton
                                    size="medium"
                                    text={openStreetMapLink(location)}
                                />
                            }
                        />
                        {allowMap && (
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
                    title={t("details")}
                    caption={
                        !exif ? (
                            <ActivityIndicator size={12} />
                        ) : !exif.tags ? (
                            t("no_exif")
                        ) : (
                            <LinkButtonUndecorated onClick={showRawExif}>
                                {t("view_exif")}
                            </LinkButtonUndecorated>
                        )
                    }
                />
                {isMLEnabled() && annotatedFaces.length > 0 && (
                    <InfoItem icon={<FaceRetouchingNaturalIcon />}>
                        <FilePeopleList
                            file={file}
                            annotatedFaceIDs={annotatedFaces}
                            onSelectFace={handleSelectFace}
                        />
                    </InfoItem>
                )}
                {showCollections &&
                    fileCollectionIDs &&
                    allCollectionsNameByID &&
                    onSelectCollection && (
                        <InfoItem icon={<FolderOutlinedIcon />}>
                            <Stack
                                direction="row"
                                sx={{
                                    gap: 1,
                                    flexWrap: "wrap",
                                    justifyContent: "flex-start",
                                    alignItems: "flex-start",
                                }}
                            >
                                {fileCollectionIDs
                                    .get(file.id)
                                    ?.filter((collectionID) =>
                                        allCollectionsNameByID.has(
                                            collectionID,
                                        ),
                                    )
                                    .map((collectionID) => (
                                        <ChipButton
                                            key={collectionID}
                                            onClick={() =>
                                                onSelectCollection(collectionID)
                                            }
                                        >
                                            {allCollectionsNameByID.get(
                                                collectionID,
                                            )}
                                        </ChipButton>
                                    ))}
                            </Stack>
                        </InfoItem>
                    )}
            </Stack>
            <RawExif
                {...rawExifVisibilityProps}
                onInfoClose={onClose}
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
type AnnotatedExif = Required<FileInfoExif> & {
    resolution?: string;
    megaPixels?: string;
    takenOnDevice?: string;
    fNumber?: string;
    exposureTime?: string;
    iso?: string;
};

const annotateExif = (
    fileInfoExif: FileInfoExif | undefined,
): AnnotatedExif | undefined => {
    if (!fileInfoExif || !fileInfoExif.tags || !fileInfoExif.parsed)
        return undefined;

    const info: AnnotatedExif = { ...fileInfoExif };

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
            info.takenOnDevice = `${exif.Make.description} ${exif.Model.description}`;

        if (exif.FNumber)
            info.fNumber = exif.FNumber.description; /* e.g. "f/16" */

        if (exif.ExposureTime)
            info.exposureTime = exif.ExposureTime.description; /* "1/10" */

        if (exif.ISOSpeedRatings)
            info.iso = `ISO${tagNumericValue(exif.ISOSpeedRatings)}`;
    }

    return info;
};

const FileInfoSidebar = styled(
    (props: Pick<DialogProps, "open" | "onClose" | "children">) => (
        <SidebarDrawer
            {...props}
            anchor="right"
            // See: [Note: Overzealous Chrome? Complicated ARIA?], but this time
            // with a different workaround.
            //
            // https://github.com/mui/material-ui/issues/43106#issuecomment-2514637251
            disableRestoreFocus={true}
            closeAfterTransition={true}
        />
    ),
)(({ theme }) => ({
    zIndex: fileInfoDrawerZ,
    // [Note: Lighter backdrop for overlays on photo viewer]
    //
    // The default backdrop color we use for the drawer in light mode is too
    // "white" when used in the image gallery because unlike the rest of the app
    // the gallery retains a black background irrespective of the mode. So use a
    // lighter scrim when overlaying content directly atop the image gallery.
    //
    // We don't need to add this special casing for nested overlays (e.g.
    // dialogs initiated from the file info drawer itself) since now there is
    // enough "white" on the screen to warrant the stronger (default) backdrop.
    ...theme.applyStyles("light", {
        ".MuiBackdrop-root": {
            backgroundColor: theme.vars.palette.backdrop.faint,
        },
    }),
}));

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
    <Stack
        direction="row"
        sx={{ alignItems: "flex-start", flex: 1, gap: "12px" }}
    >
        <InfoItemIconContainer>{icon}</InfoItemIconContainer>
        {children ? (
            <Box sx={{ flex: 1, mt: "4px" }}>{children}</Box>
        ) : (
            <Stack sx={{ flex: 1, mt: "4px", gap: "4px" }}>
                <Typography sx={{ wordBreak: "break-all" }}>{title}</Typography>
                <Typography
                    variant="small"
                    {...(typeof caption == "string"
                        ? {}
                        : { component: "div" })}
                    sx={{ color: "text.muted" }}
                >
                    {caption}
                </Typography>
            </Stack>
        )}
        {trailingButton}
    </Stack>
);

const InfoItemIconContainer = styled("div")(
    ({ theme }) => `
    width: 48px;
    aspect-ratio: 1;
    display: flex;
    justify-content: center;
    align-items: center;
    color: ${theme.vars.palette.stroke.muted}
`,
);

type EditButtonProps = ButtonishProps & {
    /**
     * If true, then an activity indicator is shown in place of the edit icon.
     */
    loading?: boolean;
};

const EditButton: React.FC<EditButtonProps> = ({ onClick, loading }) => (
    <IconButton onClick={onClick} disabled={!!loading} color="secondary">
        {!loading ? (
            <EditIcon />
        ) : (
            <CircularProgress size={"24px"} color="inherit" />
        )}
    </IconButton>
);

interface CaptionFormValues {
    caption: string;
}

type CaptionProps = Pick<
    FileInfoProps,
    "allowEdits" | "scheduleUpdate" | "refreshPhotoswipe"
> & {
    /* TODO(PS): This is DisplayFile, but that's meant to be removed */
    file: EnteFile & {
        title?: string;
    };
};

const Caption: React.FC<CaptionProps> = ({
    file,
    allowEdits,
    scheduleUpdate,
    refreshPhotoswipe,
}) => {
    const [caption, setCaption] = useState(file.pubMagicMetadata?.data.caption);

    const [loading, setLoading] = useState(false);

    const saveEdits = async (newCaption: string) => {
        try {
            if (caption === newCaption) {
                return;
            }
            setCaption(newCaption);

            const updatedFile = await changeCaption(file, newCaption);
            updateExistingFilePubMetadata(file, updatedFile);
            // @ts-ignore
            file.title = file.pubMagicMetadata.data.caption;
            refreshPhotoswipe();
            scheduleUpdate();
        } catch (e) {
            log.error("failed to update caption", e);
        }
    };

    const onSubmit = async (values: CaptionFormValues) => {
        try {
            setLoading(true);
            await saveEdits(values.caption);
        } finally {
            setLoading(false);
        }
    };

    if (!caption?.length && !allowEdits) {
        return <></>;
    }

    return (
        <Box sx={{ p: 1 }}>
            <Formik<CaptionFormValues>
                // @ts-ignore
                initialValues={{ caption }}
                validationSchema={Yup.object().shape({
                    caption: Yup.string().max(
                        5000,
                        t("caption_character_limit"),
                    ),
                })}
                validateOnBlur={false}
                onSubmit={onSubmit}
            >
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                    resetForm,
                }) => (
                    <form noValidate onSubmit={handleSubmit}>
                        <TextField
                            hiddenLabel
                            fullWidth
                            id="caption"
                            name="caption"
                            type="text"
                            multiline
                            placeholder={t("caption_placeholder")}
                            value={values.caption}
                            onChange={handleChange("caption")}
                            error={Boolean(errors.caption)}
                            helperText={errors.caption}
                            disabled={!allowEdits || loading}
                        />
                        {values.caption !== caption && (
                            <FlexWrapper justifyContent={"flex-end"}>
                                <IconButton type="submit" disabled={loading}>
                                    {loading ? (
                                        <CircularProgress
                                            size={"18px"}
                                            color="inherit"
                                        />
                                    ) : (
                                        <DoneIcon />
                                    )}
                                </IconButton>
                                <IconButton
                                    onClick={() =>
                                        resetForm({
                                            values: { caption: caption ?? "" },
                                            touched: { caption: false },
                                        })
                                    }
                                    disabled={loading}
                                >
                                    <CloseIcon />
                                </IconButton>
                            </FlexWrapper>
                        )}
                    </form>
                )}
            </Formik>
        </Box>
    );
};

type CreationTimeProps = Pick<
    FileInfoProps,
    "allowEdits" | "scheduleUpdate"
> & {
    file: EnteFile;
};

const CreationTime: React.FC<CreationTimeProps> = ({
    file,
    allowEdits,
    scheduleUpdate,
}) => {
    const { onGenericError } = useBaseContext();

    const [isEditing, setIsEditing] = useState(false);
    const [isSaving, setIsSaving] = useState(false);

    const originalDate = fileCreationPhotoDate(
        file,
        filePublicMagicMetadata(file),
    );

    const saveEdits = async (pickedTime: ParsedMetadataDate) => {
        setIsEditing(false);
        setIsSaving(true);

        const { dateTime, timestamp: editedTime } = pickedTime;
        if (editedTime != originalDate.getTime()) {
            // If not same as before.
            try {
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
                await updateRemotePublicMagicMetadata(file, {
                    dateTime,
                    editedTime,
                });

                scheduleUpdate();
            } catch (e) {
                onGenericError(e);
            }
        }

        setIsSaving(false);
    };

    return (
        <>
            <InfoItem
                icon={<CalendarTodayIcon />}
                title={formattedDate(originalDate)}
                caption={formattedTime(originalDate)}
                trailingButton={
                    allowEdits && (
                        <EditButton
                            onClick={() => setIsEditing(true)}
                            loading={isSaving}
                        />
                    )
                }
            />
            {isEditing && (
                <FileDateTimePicker
                    initialValue={originalDate}
                    onAccept={saveEdits}
                    onDidClose={() => setIsEditing(false)}
                />
            )}
        </>
    );
};

type FileNameProps = Pick<FileInfoProps, "allowEdits" | "scheduleUpdate"> & {
    file: EnteFile;
    annotatedExif: AnnotatedExif | undefined;
};

const FileName: React.FC<FileNameProps> = ({
    file,
    annotatedExif,
    allowEdits,
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

    const icon =
        file.metadata.fileType === FileType.video ? (
            <VideocamOutlinedIcon />
        ) : (
            <PhotoOutlinedIcon />
        );

    const fileSize = file.info?.fileSize;
    const caption = createMultipartCaption(
        annotatedExif?.megaPixels,
        annotatedExif?.resolution,
        fileSize ? formattedByteSize(fileSize) : undefined,
    );

    return (
        <>
            <InfoItem
                icon={icon}
                title={[fileName, extension].join(".")}
                caption={caption}
                trailingButton={
                    allowEdits && <EditButton onClick={openEditMode} />
                }
            />
            <FileNameEditDialog
                isInEditMode={isInEditMode}
                closeEditMode={closeEditMode}
                filename={fileName!}
                extension={extension}
                saveEdits={saveEdits}
            />
        </>
    );
};

const createMultipartCaption = (
    p1: string | undefined,
    p2: string | undefined,
    p3: string | undefined,
) => (
    <Stack direction="row" sx={{ gap: 1 }}>
        {p1 && <div>{p1}</div>}
        {p2 && <div>{p2}</div>}
        {p3 && <div>{p3}</div>}
    </Stack>
);

interface FileNameEditDialogProps {
    isInEditMode: boolean;
    closeEditMode: () => void;
    filename: string;
    extension: string | undefined;
    saveEdits: (name: string) => Promise<void>;
}

const FileNameEditDialog: React.FC<FileNameEditDialogProps> = ({
    isInEditMode,
    closeEditMode,
    filename,
    extension,
    saveEdits,
}) => {
    const onSubmit: SingleInputFormProps["callback"] = async (
        filename,
        setFieldError,
    ) => {
        try {
            await saveEdits(filename);
            closeEditMode();
        } catch (e) {
            log.error(e);
            setFieldError(t("generic_error_retry"));
        }
    };
    return (
        <TitledMiniDialog
            sx={{ zIndex: aboveFileViewerContentZ }}
            open={isInEditMode}
            onClose={closeEditMode}
            title={t("rename_file")}
        >
            <SingleInputForm
                initialValue={filename}
                callback={onSubmit}
                placeholder={t("enter_file_name")}
                buttonText={t("rename")}
                fieldType="text"
                caption={extension}
                secondaryButtonAction={closeEditMode}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </TitledMiniDialog>
    );
};

const openStreetMapLink = ({ latitude, longitude }: Location) =>
    `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=15/${latitude}/${longitude}`;

interface MapBoxProps {
    location: Location;
    mapEnabled: boolean;
    openUpdateMapConfirmationDialog: () => void;
}

const MapBox: React.FC<MapBoxProps> = ({
    location,
    mapEnabled,
    openUpdateMapConfirmationDialog,
}) => {
    const urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
    const attribution =
        '&copy; <a target="_blank" rel="noopener" href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    const zoom = 16;

    const mapBoxContainerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const mapContainer = mapBoxContainerRef.current;
        if (mapEnabled) {
            const position: L.LatLngTuple = [
                location.latitude,
                location.longitude,
            ];
            if (mapContainer && !mapContainer.hasChildNodes()) {
                // @ts-ignore
                const map = leaflet.map(mapContainer).setView(position, zoom);
                // @ts-ignore
                leaflet
                    .tileLayer(urlTemplate, {
                        attribution,
                    })
                    .addTo(map);
                // @ts-ignore
                leaflet.marker(position).addTo(map).openPopup();
            }
        } else {
            if (mapContainer?.hasChildNodes()) {
                if (mapContainer.firstChild) {
                    mapContainer.removeChild(mapContainer.firstChild);
                }
            }
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [mapEnabled]);

    return mapEnabled ? (
        <MapBoxContainer ref={mapBoxContainerRef} />
    ) : (
        <MapBoxEnableContainer>
            <ChipButton onClick={openUpdateMapConfirmationDialog}>
                {t("enable_map")}
            </ChipButton>
        </MapBoxEnableContainer>
    );
};

const MapBoxContainer = styled("div")`
    height: 200px;
    width: 100%;
`;

const MapBoxEnableContainer = styled(MapBoxContainer)(
    ({ theme }) => `
    position: relative;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: ${theme.vars.palette.fill.fainter};
`,
);

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
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                    typeof tag.description == "string"
                ) {
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
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
                    <CopyButton size="small" text={JSON.stringify(tags)} />
                }
            />
            <Stack sx={{ gap: 2, py: 3, px: 1 }}>
                {items.map(([key, namespace, tagName, description]) => (
                    <ExifItem key={key}>
                        <Stack direction="row" sx={{ gap: 1 }}>
                            <Typography
                                variant="small"
                                sx={{ color: "text.muted" }}
                            >
                                {tagName}
                            </Typography>
                            <Typography
                                variant="tiny"
                                sx={{ color: "text.faint" }}
                            >
                                {namespace}
                            </Typography>
                        </Stack>
                        <EllipsizedTypography sx={{ width: "100%" }}>
                            {description}
                        </EllipsizedTypography>
                    </ExifItem>
                ))}
            </Stack>
        </FileInfoSidebar>
    );
};

const ExifItem = styled("div")`
    padding-left: 8px;
    padding-right: 8px;
    display: flex;
    flex-direction: column;
    gap: 4px;
`;
