import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import LocationOnOutlinedIcon from "@mui/icons-material/LocationOnOutlined";
import PersonOutlineIcon from "@mui/icons-material/PersonOutline";
import PhotoOutlinedIcon from "@mui/icons-material/PhotoOutlined";
import TextSnippetOutlinedIcon from "@mui/icons-material/TextSnippetOutlined";
import VideocamOutlinedIcon from "@mui/icons-material/VideocamOutlined";
import {
    Link,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import type { Location } from "ente-base/types";
import {
    SidebarDrawer,
    SidebarDrawerTitlebar,
} from "ente-base/components/mui/SidebarDrawer";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { formattedDate, formattedTime } from "ente-base/i18n-date";
import { CopyButton } from "ente-gallery/components/FileInfoComponents";
import type { RawExifTags } from "ente-gallery/services/exif";
import { formattedByteSize } from "ente-gallery/utils/units";
import type { EnteFile } from "ente-media/file";
import {
    fileCreationPhotoDate,
    fileDurationString,
    fileFileName,
    fileLocation,
    type ParsedMetadata,
} from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import { t } from "i18next";
import type { ReactNode } from "react";

export interface FileInfoExif {
    tags: RawExifTags | undefined;
    parsed: ParsedMetadata | undefined;
}

export type FileInfoProps = ModalVisibilityProps & {
    file: EnteFile;
    exif: FileInfoExif | undefined;
    allowEdits?: boolean;
    allowMap?: boolean;
    showCollections?: boolean;
    fileCollectionIDs?: Map<number, number[]>;
    collectionNameByID?: Map<number, string>;
    onFileMetadataUpdate?: () => Promise<void>;
    onUpdateCaption: (fileID: number, newCaption: string) => void;
    onSelectCollection?: (collectionID: number) => void;
    onSelectPerson?: (personID: string) => void;
};

export const FileInfo: React.FC<FileInfoProps> = ({
    open,
    onClose,
    file,
    exif,
}) => {
    const caption = file.pubMagicMetadata?.data.caption ?? exif?.parsed?.description;
    const location = fileLocation(file) ?? exif?.parsed?.location;
    const uploaderName = file.pubMagicMetadata?.data.uploaderName;
    const date = fileCreationPhotoDate(file);
    const mediaDetails = mediaDetailsCaption(file, exif?.parsed);

    return (
        <FileInfoSidebar anchor="right" {...{ open, onClose }}>
            <SidebarDrawerTitlebar
                onClose={onClose}
                onRootClose={onClose}
                title={t("info")}
            />
            <Stack sx={{ px: 1, pt: 1, pb: 3, gap: "16px" }}>
                <InfoRow
                    icon={
                        file.metadata.fileType === FileType.video ? (
                            <VideocamOutlinedIcon />
                        ) : (
                            <PhotoOutlinedIcon />
                        )
                    }
                    title={fileFileName(file)}
                    caption={[
                        fileTypeLabel(file),
                        mediaDetails,
                    ]
                        .filter(Boolean)
                        .join(" • ")}
                    action={<CopyButton text={fileFileName(file)} size="small" />}
                />

                <InfoRow
                    icon={<CalendarTodayIcon />}
                    title={formattedDate(date)}
                    caption={formattedTime(date)}
                />

                {caption && (
                    <InfoRow
                        icon={<TextSnippetOutlinedIcon />}
                        title={caption}
                        caption="Caption"
                    />
                )}

                {location && (
                    <InfoRow
                        icon={<LocationOnOutlinedIcon />}
                        title={locationLabel(location)}
                        caption={
                            <Link
                                href={openStreetMapLink(location)}
                                target="_blank"
                                rel="noopener"
                                sx={{ fontWeight: "medium" }}
                            >
                                {t("view_on_map")}
                            </Link>
                        }
                        action={
                            <CopyButton
                                text={openStreetMapLink(location)}
                                size="small"
                            />
                        }
                    />
                )}

                {uploaderName && (
                    <InfoRow
                        icon={<PersonOutlineIcon />}
                        title={uploaderName}
                        caption="Uploader"
                    />
                )}
            </Stack>
        </FileInfoSidebar>
    );
};

const fileTypeLabel = (file: EnteFile) => {
    switch (file.metadata.fileType) {
        case FileType.video:
            return t("video");
        case FileType.livePhoto:
            return t("live_photo");
        case FileType.image:
        default:
            return t("image");
    }
};

const mediaDetailsCaption = (
    file: EnteFile,
    parsed: ParsedMetadata | undefined,
) =>
    [
        parsed?.width && parsed?.height
            ? `${parsed.width} × ${parsed.height}`
            : undefined,
        file.info?.fileSize
            ? formattedByteSize(file.info.fileSize)
            : undefined,
        fileDurationString(file),
    ]
        .filter(Boolean)
        .join(" • ");

const locationLabel = ({ latitude, longitude }: Location) =>
    `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;

const openStreetMapLink = ({ latitude, longitude }: Location) =>
    `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=15/${latitude}/${longitude}`;

const FileInfoSidebar = styled(SidebarDrawer)({
    "& .MuiDrawer-paper": {
        overflowX: "hidden",
    },
});

const InfoRow: React.FC<{
    icon: ReactNode;
    title: ReactNode;
    caption?: ReactNode;
    action?: ReactNode;
}> = ({ icon, title, caption, action }) => (
    <Stack direction="row" sx={{ gap: 1.5, alignItems: "flex-start" }}>
        <IconContainer>{icon}</IconContainer>
        <Stack sx={{ minWidth: 0, flex: 1, gap: 0.25 }}>
            <Typography sx={{ wordBreak: "break-word", fontWeight: "medium" }}>
                {title}
            </Typography>
            {caption && (
                <Typography
                    variant="small"
                    sx={{ color: "text.muted", wordBreak: "break-word" }}
                >
                    {caption}
                </Typography>
            )}
        </Stack>
        {action}
    </Stack>
);

const IconContainer = styled("div")(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: theme.vars.palette.text.muted,
    paddingTop: "2px",
}));
