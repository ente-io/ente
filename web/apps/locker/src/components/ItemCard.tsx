import CheckCircleRoundedIcon from "@mui/icons-material/CheckCircleRounded";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import EditOutlinedIcon from "@mui/icons-material/EditOutlined";
import FileDownloadOutlinedIcon from "@mui/icons-material/FileDownloadOutlined";
import LinkOutlinedIcon from "@mui/icons-material/LinkOutlined";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import RadioButtonUncheckedRoundedIcon from "@mui/icons-material/RadioButtonUncheckedRounded";
import RestoreIcon from "@mui/icons-material/Restore";
import ShareOutlinedIcon from "@mui/icons-material/ShareOutlined";
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
import { lockerItemIcon, lockerItemIconConfig } from "components/lockerItemIcons";
import type { LockerFileShareLinkSummary } from "services/remote";
import { downloadLockerFile } from "services/remote";
import type { AccountCredentialData, GenericFileData, LockerItem } from "types";
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
    /** Optional hint shown when delete is unavailable for this item. */
    deleteDisabledHint?: string;
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
    deleteDisabledHint,
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
    const [downloadProgress, setDownloadProgress] = useState<number | null>(
        null,
    );
    const longPressTimerRef = React.useRef<number | null>(null);
    const longPressTriggeredRef = React.useRef(false);

    const copyToClipboard = useCallback((value: string, fieldName: string) => {
        void navigator.clipboard.writeText(value).then(() => {
            setCopiedField(fieldName);
            setDownloadError(false);
        });
    }, []);

    const handleDownload = useCallback(async () => {
        if (!masterKey || downloading || !hasDownloadableObject(item)) return;
        setDownloading(true);
        setDownloadProgress(null);
        try {
            const fileName = getItemTitle(item);
            await downloadLockerFile(
                item.id,
                fileName,
                masterKey,
                ({ loaded, total }) => {
                    if (total && total > 0) {
                        setDownloadProgress(
                            Math.min(100, Math.round((loaded / total) * 100)),
                        );
                    }
                },
            );
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
                            deleteDisabledHint={deleteDisabledHint}
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
                            <Tooltip
                                title={shareLinkTooltipLabel(fileShareLink)}
                            >
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
                            deleteDisabledHint={deleteDisabledHint}
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
                            deleteDisabledHint={deleteDisabledHint}
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
                        : t("copiedToClipboard", { fieldName: copiedField })
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
    deleteDisabledHint?: string;
    onDownload: () => Promise<void>;
    onShareLink?: (item: LockerItem) => void;
    downloading: boolean;
}> = ({ item, onEdit, onDelete, deleteDisabledHint, onShareLink }) => (
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
        {onDelete ? (
            <OverflowMenuOption
                startIcon={<DeleteOutlineIcon />}
                color="critical"
                onClick={() => onDelete(item)}
            >
                {t("delete")}
            </OverflowMenuOption>
        ) : (
            deleteDisabledHint && (
                <OverflowMenuOption
                    startIcon={<DeleteOutlineIcon />}
                    color="critical"
                    disabled
                    onClick={() => undefined}
                >
                    {t("delete")}
                </OverflowMenuOption>
            )
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
        <Stack direction="row" sx={{ gap: 0.25, flexShrink: 0 }}>
            <Tooltip
                title={showPassword ? t("hidePassword") : t("showPassword")}
            >
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
    return lockerItemIconConfig(
        item.type,
        item.type === "file" ? (item.data as GenericFileData).name : undefined,
    ).backgroundColor;
};

/** Icon for a LockerItem. */
const itemIcon = (item: LockerItem) => {
    return lockerItemIcon(item.type, {
        fileName:
            item.type === "file"
                ? (item.data as GenericFileData).name
                : undefined,
        size: 20,
        strokeWidth: 1.9,
    });
};
