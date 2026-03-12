import AudioFileOutlinedIcon from "@mui/icons-material/AudioFileOutlined";
import CheckCircleRoundedIcon from "@mui/icons-material/CheckCircleRounded";
import ContactEmergencyOutlinedIcon from "@mui/icons-material/ContactEmergencyOutlined";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import DescriptionOutlinedIcon from "@mui/icons-material/DescriptionOutlined";
import EditOutlinedIcon from "@mui/icons-material/EditOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import ImageOutlinedIcon from "@mui/icons-material/ImageOutlined";
import InsertDriveFileOutlinedIcon from "@mui/icons-material/InsertDriveFileOutlined";
import KeyOutlinedIcon from "@mui/icons-material/KeyOutlined";
import LinkOutlinedIcon from "@mui/icons-material/LinkOutlined";
import LocationOnOutlinedIcon from "@mui/icons-material/LocationOnOutlined";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import NoteOutlinedIcon from "@mui/icons-material/NoteOutlined";
import RadioButtonUncheckedRoundedIcon from "@mui/icons-material/RadioButtonUncheckedRounded";
import RestoreIcon from "@mui/icons-material/Restore";
import ShareOutlinedIcon from "@mui/icons-material/ShareOutlined";
import VideoFileOutlinedIcon from "@mui/icons-material/VideoFileOutlined";
import VisibilityIcon from "@mui/icons-material/Visibility";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import {
    Box,
    ButtonBase,
    CircularProgress,
    IconButton,
    Snackbar,
    Stack,
    Tooltip,
    Typography,
} from "@mui/material";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import log from "ente-base/log";
import { t } from "i18next";
import React, { useCallback, useState } from "react";
import type { LockerFileShareLinkSummary } from "services/remote";
import { downloadLockerFile } from "services/remote";
import type {
    AccountCredentialData,
    GenericFileData,
    LockerItem,
} from "types";
import { getItemTitle, hasDownloadableObject } from "types";

interface ItemCardProps {
    item: LockerItem;
    /** The user's master key, needed for file downloads. */
    masterKey?: string;
    secondaryText?: string;
    onClick: () => void;
    /** Whether this card is shown in the trash view. */
    isTrashView?: boolean;
    /** Called when the user wants to edit this item. */
    onEdit?: (item: LockerItem) => void;
    /** Called when the user wants to delete (trash) this item. */
    onDelete?: (item: LockerItem) => void;
    /** Called when the user wants to permanently delete this item. */
    onPermanentlyDelete?: (items: LockerItem[]) => void;
    /** Called when the user wants to restore this item from trash. */
    onRestore?: (item: LockerItem) => void;
    onShareLink?: (item: LockerItem) => void;
    fileShareLink?: LockerFileShareLinkSummary;
    selectionMode?: boolean;
    selectable?: boolean;
    selected?: boolean;
    onToggleSelection?: (item: LockerItem) => void;
    onLongPressSelect?: (item: LockerItem) => void;
}

/**
 * A file/item row matching the Figma design:
 * Light rounded card background — colored icon (in rounded square) — title — actions
 */
export const ItemCard: React.FC<ItemCardProps> = ({
    item,
    masterKey,
    secondaryText,
    onClick,
    isTrashView,
    onEdit,
    onDelete,
    onPermanentlyDelete,
    onRestore,
    onShareLink,
    fileShareLink,
    selectionMode,
    selectable,
    selected,
    onToggleSelection,
    onLongPressSelect,
}) => {
    const [copiedField, setCopiedField] = useState<string | null>(null);
    const [downloadError, setDownloadError] = useState(false);
    const [downloading, setDownloading] = useState(false);
    const [downloadProgress, setDownloadProgress] = useState<number | null>(null);
    const longPressTimerRef = React.useRef<number | null>(null);
    const longPressTriggeredRef = React.useRef(false);

    const copyToClipboard = useCallback(
        (value: string, fieldName: string) => {
            void navigator.clipboard.writeText(value).then(() => {
                setCopiedField(fieldName);
                setDownloadError(false);
            });
        },
        [],
    );

    const handleDownload = useCallback(async () => {
        if (!masterKey || downloading || !hasDownloadableObject(item)) return;
        setDownloading(true);
        setDownloadProgress(null);
        try {
            const fileName = getItemTitle(item);
            await downloadLockerFile(item.id, fileName, masterKey, ({ loaded, total }) => {
                if (total && total > 0) {
                    setDownloadProgress(Math.min(100, Math.round((loaded / total) * 100)));
                }
            });
        } catch (e) {
            log.error(`Failed to download file ${item.id}`, e);
            setDownloadError(true);
        } finally {
            setDownloading(false);
            setDownloadProgress(null);
        }
    }, [item, masterKey, downloading]);

const title = getItemTitle(item);
    const downloadable = hasDownloadableObject(item);
    const isExpiredShareLink =
        !!fileShareLink?.validTill &&
        fileShareLink.validTill > 0 &&
        fileShareLink.validTill < Date.now() * 1000;
    const clearLongPress = useCallback(() => {
        if (longPressTimerRef.current !== null) {
            window.clearTimeout(longPressTimerRef.current);
            longPressTimerRef.current = null;
        }
    }, []);
    const handlePressStart = useCallback(
        (event: React.PointerEvent<HTMLDivElement>) => {
            if (
                selectionMode ||
                !selectable ||
                !onLongPressSelect ||
                (event.button !== -1 && event.button !== 0)
            ) {
                return;
            }

            const target = event.target;
            if (
                target instanceof Element &&
                target.closest("[data-no-long-press='true']")
            ) {
                return;
            }

            clearLongPress();
            longPressTriggeredRef.current = false;
            longPressTimerRef.current = window.setTimeout(() => {
                longPressTriggeredRef.current = true;
                onLongPressSelect(item);
            }, 420);
        },
        [clearLongPress, item, onLongPressSelect, selectable, selectionMode],
    );
    const handlePressEnd = useCallback(() => {
        clearLongPress();
    }, [clearLongPress]);

    React.useEffect(
        () => () => {
            clearLongPress();
        },
        [clearLongPress],
    );

    return (
        <>
            <ButtonBase
                component="div"
                onPointerDown={handlePressStart}
                onPointerUp={handlePressEnd}
                onPointerLeave={handlePressEnd}
                onPointerCancel={handlePressEnd}
                onContextMenu={(event) => {
                    if (!selectionMode && selectable && onLongPressSelect) {
                        event.preventDefault();
                    }
                }}
                onClick={() => {
                    if (longPressTriggeredRef.current) {
                        longPressTriggeredRef.current = false;
                        return;
                    }
                    if (selectionMode) {
                        if (selectable && onToggleSelection) {
                            onToggleSelection(item);
                        }
                        return;
                    }
                    onClick();
                }}
                sx={(theme) => ({
                    display: "flex",
                    width: "100%",
                    textAlign: "left",
                    borderRadius: "14px",
                    overflow: "hidden",
                    px: 1.5,
                    py: 1.25,
                    gap: 1.5,
                    alignItems: "center",
                    backgroundColor: theme.vars.palette.fill.faint,
                    mb: 0.75,
                    transition: "background-color 0.15s",
                    opacity: selectionMode && !selectable ? 0.58 : 1,
                    "&:hover": {
                        backgroundColor: theme.vars.palette.fill.faintHover,
                    },
                })}
            >
                {selectionMode && (
                    <Box
                        sx={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            width: 24,
                            flexShrink: 0,
                            color: selected ? "primary.main" : "text.faint",
                        }}
                    >
                        {selectable ? (
                            selected ? (
                                <CheckCircleRoundedIcon sx={{ fontSize: 22 }} />
                            ) : (
                                <RadioButtonUncheckedRoundedIcon
                                    sx={{ fontSize: 22 }}
                                />
                            )
                        ) : null}
                    </Box>
                )}

                {/* Type icon — colored per type in rounded square */}
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        width: 40,
                        height: 40,
                        borderRadius: "10px",
                        backgroundColor: iconBgColor(item),
                        flexShrink: 0,
                    }}
                >
                    {itemIcon(item)}
                </Box>

                {/* Title */}
                <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Typography
                        variant="body"
                        sx={{ fontWeight: "medium", lineHeight: 1.4 }}
                        noWrap
                    >
                        {title}
                    </Typography>
                    {secondaryText && (
                        <Typography
                            variant="small"
                            sx={{
                                color: "text.muted",
                                display: "block",
                                mt: 0.25,
                            }}
                            noWrap
                        >
                            {secondaryText}
                        </Typography>
                    )}
                </Box>

                {/* Quick actions */}
                {selectionMode ? null : isTrashView ? (
                    <TrashActions
                        item={item}
                        onRestore={onRestore}
                        onPermanentlyDelete={onPermanentlyDelete}
                    />
                ) : item.type === "accountCredential" ? (
                    <Stack
                        direction="row"
                        sx={{ gap: 0, alignItems: "center" }}
                        data-no-long-press="true"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <CredentialActions
                            data={item.data as AccountCredentialData}
                            onCopy={copyToClipboard}
                        />
                        <ItemOverflowMenu
                            item={item}
                            masterKey={masterKey}
                            onEdit={onEdit}
                            onDelete={onDelete}
                            onDownload={handleDownload}
                            onShareLink={onShareLink}
                            downloading={downloading}
                        />
                    </Stack>
                ) : item.type === "file" && masterKey && downloadable ? (
                    <Stack
                        direction="row"
                        sx={{ gap: 0, alignItems: "center" }}
                        data-no-long-press="true"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {fileShareLink && onShareLink && (
                            <Tooltip title={shareLinkTooltipLabel(fileShareLink)}>
                                <IconButton
                                    size="small"
                                    onClick={() => onShareLink(item)}
                                    sx={{
                                        color: isExpiredShareLink
                                            ? "warning.main"
                                            : "primary.main",
                                    }}
                                >
                                    <LinkOutlinedIcon sx={{ fontSize: 18 }} />
                                </IconButton>
                            </Tooltip>
                        )}
                        <Tooltip title={t("download")}>
                            <IconButton
                                size="small"
                                onClick={() => void handleDownload()}
                                sx={{
                                    color: downloading
                                        ? "primary.main"
                                        : "text.faint",
                                }}
                                disabled={downloading}
                            >
                                {downloading && downloadProgress !== null ? (
                                    <Box
                                        sx={{
                                            position: "relative",
                                            display: "inline-flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}
                                    >
                                        <CircularProgress
                                            variant="determinate"
                                            value={downloadProgress}
                                            size={20}
                                            thickness={5}
                                        />
                                    </Box>
                                ) : (
                                    <FileDownloadOutlinedIcon
                                        sx={{ fontSize: 20 }}
                                    />
                                )}
                            </IconButton>
                        </Tooltip>
                        {downloading && downloadProgress !== null && (
                            <Typography
                                variant="mini"
                                sx={{ color: "text.faint", minWidth: 34 }}
                            >
                                {downloadProgress}%
                            </Typography>
                        )}
                        <ItemOverflowMenu
                            item={item}
                            masterKey={masterKey}
                            onEdit={onEdit}
                            onDelete={onDelete}
                            onDownload={handleDownload}
                            onShareLink={onShareLink}
                            downloading={downloading}
                        />
                    </Stack>
                ) : (
                    <Box
                        sx={{ flexShrink: 0 }}
                        data-no-long-press="true"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <ItemOverflowMenu
                            item={item}
                            masterKey={masterKey}
                            onEdit={onEdit}
                            onDelete={onDelete}
                            onDownload={handleDownload}
                            onShareLink={onShareLink}
                            downloading={downloading}
                        />
                    </Box>
                )}
            </ButtonBase>

            <Snackbar
                open={copiedField !== null || downloadError}
                message={
                    downloadError
                        ? t("downloadFailed")
                        : t("copiedToClipboard", {
                              fieldName: copiedField,
                          })
                }
                autoHideDuration={2000}
                onClose={() => {
                    setCopiedField(null);
                    setDownloadError(false);
                }}
            />
        </>
    );
};

const formatShareLinkDate = (timestamp: number) =>
    new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(
        new Date(timestamp / 1000),
    );

const shareLinkTooltipLabel = (fileShareLink: LockerFileShareLinkSummary) => {
    const parts = [
        fileShareLink.validTill &&
        fileShareLink.validTill > 0 &&
        fileShareLink.validTill < Date.now() * 1000
            ? t("shareLinkExpiredHint")
            : t("shareLinkActiveHint"),
    ];

    if (fileShareLink.validTill && fileShareLink.validTill > 0) {
        parts.push(
            t("shareLinkExpiresOn", {
                date: formatShareLinkDate(fileShareLink.validTill),
            }),
        );
    }

    if (!fileShareLink.enableDownload) {
        parts.push(t("shareLinkDownloadDisabledHint"));
    }

    return parts.join(" • ");
};

// ---------------------------------------------------------------------------
// Overflow menu for item actions
// ---------------------------------------------------------------------------

const ItemOverflowMenu: React.FC<{
    item: LockerItem;
    masterKey?: string;
    onEdit?: (item: LockerItem) => void;
    onDelete?: (item: LockerItem) => void;
    onDownload: () => Promise<void>;
    onShareLink?: (item: LockerItem) => void;
    downloading: boolean;
}> = ({ item, onEdit, onDelete, onShareLink }) => (
    <OverflowMenu
        ariaID={`item-menu-${item.id}`}
        triggerButtonIcon={<MoreVertIcon sx={{ fontSize: 20 }} />}
        triggerButtonSxProps={{ color: "text.faint", p: 0.5 }}
    >
        {item.type !== "file" && onEdit && (
            <OverflowMenuOption
                startIcon={<EditOutlinedIcon />}
                onClick={() => onEdit(item)}
            >
                {t("edit")}
            </OverflowMenuOption>
        )}
        {item.type === "file" && onShareLink && (
            <OverflowMenuOption
                startIcon={<ShareOutlinedIcon />}
                onClick={() => onShareLink(item)}
            >
                {t("shareLink")}
            </OverflowMenuOption>
        )}
        {onDelete && (
            <OverflowMenuOption
                startIcon={<DeleteOutlineIcon />}
                color="critical"
                onClick={() => onDelete(item)}
            >
                {t("delete")}
            </OverflowMenuOption>
        )}
    </OverflowMenu>
);

// ---------------------------------------------------------------------------
// Trash-specific actions
// ---------------------------------------------------------------------------

const TrashActions: React.FC<{
    item: LockerItem;
    onRestore?: (item: LockerItem) => void;
    onPermanentlyDelete?: (items: LockerItem[]) => void;
}> = ({ item, onRestore, onPermanentlyDelete }) => (
    <Stack
        direction="row"
        sx={{ gap: 0, flexShrink: 0 }}
        onClick={(e) => e.stopPropagation()}
    >
        {onRestore && (
            <Tooltip title={t("restore")}>
                <IconButton
                    size="small"
                    onClick={() => onRestore(item)}
                    sx={{ color: "text.faint" }}
                >
                    <RestoreIcon sx={{ fontSize: 20 }} />
                </IconButton>
            </Tooltip>
        )}
        {onPermanentlyDelete && (
            <Tooltip title={t("permanentlyDelete")}>
                <IconButton
                    size="small"
                    onClick={() => onPermanentlyDelete([item])}
                    sx={{ color: "critical.main" }}
                >
                    <DeleteOutlineIcon sx={{ fontSize: 20 }} />
                </IconButton>
            </Tooltip>
        )}
    </Stack>
);

/** Inline credential quick-actions (password show/copy). */
const CredentialActions: React.FC<{
    data: AccountCredentialData;
    onCopy: (value: string, field: string) => void;
}> = ({ data, onCopy }) => {
    const [showPassword, setShowPassword] = useState(false);

    return (
        <Stack
            direction="row"
            sx={{ gap: 0.25, flexShrink: 0 }}
        >
            <Tooltip title={showPassword ? t("hidePassword") : t("showPassword")}>
                <IconButton
                    size="small"
                    onClick={() => setShowPassword(!showPassword)}
                >
                    {showPassword ? (
                        <VisibilityOffIcon sx={{ fontSize: 18 }} />
                    ) : (
                        <VisibilityIcon sx={{ fontSize: 18 }} />
                    )}
                </IconButton>
            </Tooltip>
            <Tooltip title={t("copyPassword")}>
                <IconButton
                    size="small"
                    onClick={() => onCopy(data.password, t("password"))}
                >
                    <ContentCopyIcon sx={{ fontSize: 16 }} />
                </IconButton>
            </Tooltip>
        </Stack>
    );
};

/**
 * Background color for the icon square, per item type.
 */
const iconBgColor = (item: LockerItem): string => {
    switch (item.type) {
        case "note":
            return "rgba(255, 179, 71, 0.15)";
        case "accountCredential":
            return "rgba(16, 113, 255, 0.15)";
        case "physicalRecord":
            return "rgba(76, 175, 80, 0.15)";
        case "emergencyContact":
            return "rgba(244, 67, 54, 0.15)";
        case "file": {
            const name = (item.data as GenericFileData).name;
            const ext = name.split(".").pop()?.toLowerCase() ?? "";
            if (
                [
                    "pdf", "doc", "docx", "txt", "rtf", "xlsx", "pptx", "csv",
                ].includes(ext)
            )
                return "rgba(244, 67, 54, 0.12)";
            if (
                [
                    "jpg", "jpeg", "png", "gif", "heic", "webp", "svg",
                ].includes(ext)
            )
                return "rgba(76, 175, 80, 0.12)";
            if (
                [
                    "mp3", "m4a", "wav", "ogg", "flac", "aac", "wma",
                ].includes(ext)
            )
                return "rgba(156, 39, 176, 0.12)";
            if (["mp4", "mov", "avi", "mkv", "webm"].includes(ext))
                return "rgba(33, 150, 243, 0.12)";
            return "rgba(158, 158, 158, 0.10)";
        }
        default:
            return "rgba(158, 158, 158, 0.10)";
    }
};

/** Icon for a LockerItem. */
const itemIcon = (item: LockerItem) => {
    switch (item.type) {
        case "note":
            return <NoteOutlinedIcon sx={{ fontSize: 20, color: "#FFB347" }} />;
        case "accountCredential":
            return <KeyOutlinedIcon sx={{ fontSize: 20, color: "#1071FF" }} />;
        case "physicalRecord":
            return (
                <LocationOnOutlinedIcon
                    sx={{ fontSize: 20, color: "#4CAF50" }}
                />
            );
        case "emergencyContact":
            return (
                <ContactEmergencyOutlinedIcon
                    sx={{ fontSize: 20, color: "#F44336" }}
                />
            );
        case "file":
            return fileIcon((item.data as GenericFileData).name);
        default:
            return (
                <InsertDriveFileOutlinedIcon
                    sx={{ fontSize: 20, color: "#9E9E9E" }}
                />
            );
    }
};

/** Pick an icon based on the file extension. */
const fileIcon = (name: string) => {
    const ext = name.split(".").pop()?.toLowerCase() ?? "";
    if (["mp3", "m4a", "wav", "ogg", "flac", "aac", "wma"].includes(ext))
        return (
            <AudioFileOutlinedIcon sx={{ fontSize: 20, color: "#9C27B0" }} />
        );
    if (["mp4", "mov", "avi", "mkv", "webm"].includes(ext))
        return (
            <VideoFileOutlinedIcon sx={{ fontSize: 20, color: "#2196F3" }} />
        );
    if (["jpg", "jpeg", "png", "gif", "heic", "webp", "svg"].includes(ext))
        return <ImageOutlinedIcon sx={{ fontSize: 20, color: "#4CAF50" }} />;
    if (
        ["pdf", "doc", "docx", "txt", "rtf", "xlsx", "pptx", "csv"].includes(
            ext,
        )
    )
        return (
            <DescriptionOutlinedIcon
                sx={{ fontSize: 20, color: "#F44336" }}
            />
        );
    return (
        <InsertDriveFileOutlinedIcon
            sx={{ fontSize: 20, color: "#9E9E9E" }}
        />
    );
};
