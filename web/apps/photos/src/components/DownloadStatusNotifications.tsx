import { useBaseContext } from "ente-base/context";
import {
    isSaveComplete,
    isSaveCompleteWithErrors,
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

    return saveGroups.map((group, index) => (
        <Notification
            key={group.id}
            horizontal="left"
            sx={{ "&&": { bottom: `${index * 80 + 20}px` } }}
            open={true}
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
        />
    ));
};
