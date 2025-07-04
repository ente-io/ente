import { useBaseContext } from "ente-base/context";
import {
    isSaveComplete,
    isSaveCompleteWithErrors,
    isSaveStarted,
    type SaveGroup,
} from "ente-gallery/components/utils/save-groups";
import { Notification } from "ente-new/photos/components/Notification";
import { t } from "i18next";

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
     * Called when the hidden section should be shown.
     *
     * This triggers the display of the dialog to authenticate the user, and the
     * returned promise when (and only if) the user successfully reauthenticates.
     *
     * Since the hidden section is only relevant in the context of the photos
     * app where there is a logged in user, this callback can be omitted in the
     * context of the public albums app.
     */
    onShowHiddenSection?: () => Promise<void>;
    /**
     * Called when the collection with the given {@link collectionID} should be
     * shown.
     *
     * This is only relevant in the context of the photos app, and can be
     * omitted by the public albums app.
     */
    onShowCollection?: (collectionID: number) => void;
}

/**
 * A component that shows a list of notifications, one each for an active
 * user-initiated download.
 */
export const DownloadStatusNotifications: React.FC<
    DownloadStatusNotificationsProps
> = ({
    saveGroups,
    onRemoveSaveGroup,
    onShowHiddenSection,
    onShowCollection,
}) => {
    const { showMiniDialog } = useBaseContext();

    const confirmCancelDownload = (group: SaveGroup) =>
        showMiniDialog({
            title: t("stop_downloads_title"),
            message: t("stop_downloads_message"),
            continue: {
                text: t("yes_stop_downloads"),
                color: "critical",
                action: () => {
                    group?.canceller.abort();
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
        if (electron) {
            electron.openDirectory(group.downloadDirPath);
        } else if (onShowCollection) {
            if (group.isHidden) {
                void onShowHiddenSection().then(() => {
                    onShowCollection(group.collectionID);
                });
            } else {
                onShowCollection(group.collectionID);
            }
        } else {
            return undefined;
        }
    };

    if (!saveGroups) {
        return <></>;
    }

    const notifications: React.ReactNode[] = [];

    let visibleIndex = 0;
    for (const group of saveGroups) {
        // Skip attempted downloads of empty albums, which had no effect.
        if (!isSaveStarted(group)) continue;

        const index = visibleIndex++;
        notifications.push(
            <Notification
                key={group.id}
                horizontal="left"
                sx={{ "&&": { bottom: `${index * 80 + 20}px` } }}
                open={isSaveStarted(group)}
                onClose={createOnClose(group)}
                keepOpenOnClick
                attributes={{
                    color: isSaveCompleteWithErrors(group)
                        ? "critical"
                        : "secondary",
                    title: isSaveCompleteWithErrors(group)
                        ? t("download_failed")
                        : isSaveComplete(group)
                          ? t("download_complete")
                          : t("downloading_album", { name: group.title }),
                    caption: isSaveComplete(group)
                        ? group.title
                        : t("download_progress", {
                              count: group.success + group.failed,
                              total: group.total,
                          }),
                    onClick: createOnClick(group),
                }}
            />,
        );
    }

    return notifications;
};
