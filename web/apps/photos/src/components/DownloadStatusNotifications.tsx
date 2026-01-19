import {
    Download01Icon,
    Loading03Icon,
    Tick02Icon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import ReplayIcon from "@mui/icons-material/Replay";
import { keyframes, styled, Typography } from "@mui/material";
import { useBaseContext } from "ente-base/context";
import {
    isSaveComplete,
    isSaveCompleteWithErrors,
    type SaveGroup,
} from "ente-gallery/components/utils/save-groups";
import { Notification } from "ente-new/photos/components/Notification";
import { t } from "i18next";

/** Maximum characters for album name before truncation */
const MAX_ALBUM_NAME_LENGTH = 25;

/** Truncate album name with ellipsis if it exceeds max length */
const truncateAlbumName = (name: string): string => {
    if (name.length <= MAX_ALBUM_NAME_LENGTH) return name;
    return name.slice(0, MAX_ALBUM_NAME_LENGTH) + "...";
};

interface DownloadStatusNotificationsProps {
    /**
     * A list of user-initiated downloads for which a status should be shown.
     *
     * An entry is added to this list when the user initiates the download, and
     * remains here until the user explicitly closes the corresponding
     * {@link Notification} component that was showing the save group's status.
     */
    saveGroups: SaveGroup[];
    /**
     * Called when the user closes the download status associated with the given
     * {@link saveGroup}.
     */
    onRemoveSaveGroup: (saveGroup: SaveGroup) => void;
    /**
     * Called when the collection summary with the given {@link collectionID}
     * should be shown. If {@link isHiddenCollectionSummary} is set, then any
     * reauthentication as appropriate before switching to the hidden section of
     * the app is performed first.
     *
     * and hidden attribute should be shown.
     *
     * This is only relevant in the context of the photos app, and can be
     * omitted by the public albums app. See the documentation of
     * {@link SaveGroup}'s {@link collectionSummaryID} property for why we don't
     * store the collection summary itself.
     */
    onShowCollectionSummary?: (
        collectionSummaryID: number | undefined,
        isHiddenCollectionSummary: boolean | undefined,
    ) => void;
}

/**
 * A component that shows a list of notifications, one each for an active
 * user-initiated download.
 */
export const DownloadStatusNotifications: React.FC<
    DownloadStatusNotificationsProps
> = ({ saveGroups, onRemoveSaveGroup, onShowCollectionSummary }) => {
    const { showMiniDialog } = useBaseContext();

    const confirmCancelDownload = (group: SaveGroup) =>
        showMiniDialog({
            title: t("stop_downloads_title"),
            message: t("stop_downloads_message"),
            continue: {
                text: t("yes_stop_downloads"),
                color: "critical",
                action: () => {
                    group.canceller.abort();
                    onRemoveSaveGroup(group);
                },
            },
            cancel: t("no"),
        });

    const createOnClose = (group: SaveGroup) => () => {
        if (isSaveComplete(group)) {
            onRemoveSaveGroup(group);
        } else {
            confirmCancelDownload(group);
        }
    };

    const createOnClick = (group: SaveGroup) => () => {
        const electron = globalThis.electron;
        if (electron && group.downloadDirPath) {
            void electron.openDirectory(group.downloadDirPath);
        } else if (onShowCollectionSummary) {
            onShowCollectionSummary(
                group.collectionSummaryID,
                group.isHiddenCollectionSummary,
            );
        } else {
            return undefined;
        }
    };

    return saveGroups.map((group, index) => {
        const hasErrors = isSaveCompleteWithErrors(group);
        const isComplete = isSaveComplete(group);
        const canRetry = hasErrors && !!group.retry;

        // Determine if this is a ZIP download (web with multiple files or live photo)
        const isZipDownload = !group.downloadDirPath && group.total > 1;
        const isDesktopOrSingleFile =
            !!group.downloadDirPath || group.total === 1;

        // Build the status text for the caption
        let statusText: React.ReactNode;
        if (hasErrors) {
            // Show specific error message based on failure reason
            if (group.failureReason === "network_offline") {
                statusText = t("download_failed_network_offline");
            } else if (group.failureReason === "file_error") {
                statusText = t("download_failed_file_error");
            } else {
                statusText = t("download_failed");
            }
        } else if (isComplete) {
            statusText = t("download_complete");
        } else if (isZipDownload) {
            const part = group.currentPart ?? 1;
            statusText = group.isDownloadingZip
                ? t("downloading_part", { part })
                : t("preparing_part", { part });
        } else if (isDesktopOrSingleFile) {
            statusText =
                group.total === 1
                    ? t("downloading_file")
                    : t("downloading_files");
        } else {
            statusText = t("downloading");
        }

        // Build caption: "Status • X / Y files"
        const progress = t("download_progress", {
            count: group.success + group.failed,
            total: group.total,
        });
        const caption = (
            <Typography
                variant="small"
                sx={{
                    color: hasErrors ? "white" : "text.muted",
                    fontVariantNumeric: "tabular-nums",
                }}
            >
                {statusText}
                {!isComplete && <> &bull; {progress}</>}
            </Typography>
        );

        // Determine the start icon based on state
        let startIcon: React.ReactNode;
        if (hasErrors) {
            startIcon = <ErrorOutlineIcon />;
        } else if (isComplete) {
            startIcon = (
                <GlowingIconWrapper>
                    <HugeiconsIcon icon={Tick02Icon} size={28} />
                </GlowingIconWrapper>
            );
        } else if (isZipDownload && !group.isDownloadingZip) {
            // Preparing state - use loading icon
            startIcon = <SpinningIcon />;
        } else {
            // Downloading state
            startIcon = (
                <DroppingIconWrapper>
                    <HugeiconsIcon icon={Download01Icon} size={28} />
                </DroppingIconWrapper>
            );
        }

        // Title is always the album name (truncated)
        const truncatedName = truncateAlbumName(group.title);

        return (
            <Notification
                key={group.id}
                horizontal="left"
                sx={(theme) => ({
                    "&&": { bottom: `${index * 80 + 20}px` },
                    width: "min(400px, 100vw)",
                    borderRadius: "20px",
                    "& .MuiButton-root": {
                        borderRadius: "20px",
                        padding: "16px 16px 16px 20px",
                    },
                    "& .MuiIconButton-root": {
                        width: "40px",
                        height: "40px",
                        "& svg": { fontSize: "22px" },
                    },
                    [theme.breakpoints.down("sm")]: {
                        "&&": { bottom: `${index * 70 + 16}px` },
                        width: "min(340px, calc(100vw - 16px))",
                        borderRadius: "16px",
                        "& .MuiButton-root": {
                            borderRadius: "16px",
                            padding: "12px 12px 12px 16px",
                        },
                        "& .MuiIconButton-root": {
                            width: "36px",
                            height: "36px",
                            "& svg": { fontSize: "20px" },
                        },
                    },
                })}
                open={true}
                onClose={createOnClose(group)}
                keepOpenOnClick
                attributes={{
                    color: hasErrors ? "critical" : "secondary",
                    startIcon,
                    title: truncatedName,
                    caption,
                    onClick: createOnClick(group),
                    endIcon: canRetry ? (
                        <ReplayIcon
                            titleAccess={t("retry")}
                            sx={{ color: "white" }}
                        />
                    ) : undefined,
                    onEndIconClick: canRetry
                        ? () => group.retry?.()
                        : undefined,
                }}
            />
        );
    });
};

/** CSS keyframes for spinning animation */
const spinAnimation = keyframes`
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
`;

/** CSS keyframes for drop from top animation */
const dropAnimation = keyframes`
    0% { transform: translateY(-100%); opacity: 0.15; }
    50% { transform: translateY(10%); opacity: 0.6; }
    100% { transform: translateY(0); opacity: 1; }
`;

/** CSS keyframes for green glow animation */
const glowAnimation = keyframes`
    0% { color: var(--mui-palette-fixed-success); }
    100% { color: inherit; }
`;

/** CSS keyframes for fade in animation */
const fadeInAnimation = keyframes`
    0% { opacity: 0; }
    100% { opacity: 1; }
`;

/** Drop animation icon wrapper */
const DroppingIconWrapper = styled("span")`
    display: inline-flex;
    animation: ${dropAnimation} 0.8s ease-out forwards;
`;

/** Glowing icon wrapper for success state */
const GlowingIconWrapper = styled("span")`
    display: inline-flex;
    animation: ${glowAnimation} 2s ease-out forwards;
`;

/** Spinning loading icon wrapper */
const SpinningIconWrapper = styled("span")`
    display: inline-flex;
    animation:
        ${fadeInAnimation} 0.5s ease-out forwards,
        ${spinAnimation} 3s linear infinite;
`;

/** Spinning loading icon */
const SpinningIcon: React.FC = () => (
    <SpinningIconWrapper>
        <HugeiconsIcon icon={Loading03Icon} size={28} />
    </SpinningIconWrapper>
);
