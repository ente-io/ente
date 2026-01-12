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
const MAX_ALBUM_NAME_LENGTH = 20;

/** Truncate album name with ellipsis if it exceeds max length */
const truncateAlbumName = (name: string): string => {
    if (name.length <= MAX_ALBUM_NAME_LENGTH) return name;
    return name.slice(0, MAX_ALBUM_NAME_LENGTH) + "...";
};

/** CSS keyframes for animating ellipsis dots */
const ellipsisAnimation = keyframes`
    0% { content: " ."; }
    33% { content: " .."; }
    66% { content: " ..."; }
`;

/** Animated ellipsis using pure CSS - no React re-renders */
const AnimatedEllipsis = styled("span")`
    &::after {
        content: " .";
        animation: ${ellipsisAnimation} 1.5s steps(1) infinite;
    }
`;

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
        const canRetry = hasErrors && !!group.retry;

        // Show specific error message based on failure reason
        let failedTitle: string;
        if (group.failureReason === "network_offline") {
            failedTitle = `${t("download_failed_network_offline")} (${group.failed}/${group.total})`;
        } else if (group.failureReason === "file_error") {
            failedTitle = `${t("download_failed_file_error")} (${group.failed}/${group.total})`;
        } else {
            failedTitle = `${t("download_failed")} (${group.failed}/${group.total})`;
        }

        // Determine if this is a ZIP download (web with multiple files or live photo)
        const isZipDownload = !group.downloadDirPath && group.total > 1;
        const isDesktopOrSingleFile =
            !!group.downloadDirPath || group.total === 1;

        // Build the title based on download type
        let progressTitle: React.ReactNode;
        if (isZipDownload) {
            const part = group.currentPart ?? 1;
            progressTitle = (
                <>
                    {group.isDownloadingZip
                        ? t("downloading_part", { part })
                        : t("preparing_part", { part })}
                    <AnimatedEllipsis />
                </>
            );
        } else if (isDesktopOrSingleFile) {
            progressTitle =
                group.total === 1
                    ? t("downloading_file")
                    : t("downloading_files");
        } else {
            progressTitle = t("downloading");
        }

        // Build caption: "X / Y files - Album Name"
        const truncatedName = truncateAlbumName(group.title);
        const progress = t("download_progress", {
            count: group.success + group.failed,
            total: group.total,
        });
        const progressCaption = (
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {progress} - {truncatedName}
            </Typography>
        );

        return (
            <Notification
                key={group.id}
                horizontal="left"
                sx={{ "&&": { bottom: `${index * 80 + 20}px` } }}
                open={true}
                onClose={createOnClose(group)}
                keepOpenOnClick
                attributes={{
                    color: hasErrors ? "critical" : "secondary",
                    title: hasErrors
                        ? failedTitle
                        : isSaveComplete(group)
                          ? t("download_complete")
                          : progressTitle,
                    caption: isSaveComplete(group)
                        ? group.title
                        : progressCaption,
                    onClick: createOnClick(group),
                    endIcon: canRetry ? (
                        <ReplayIcon titleAccess={t("retry")} />
                    ) : undefined,
                    onEndIconClick: canRetry
                        ? () => group.retry?.()
                        : undefined,
                }}
            />
        );
    });
};
