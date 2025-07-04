// TODO: Audit this file
/* eslint-disable react-refresh/only-export-components */
import { useBaseContext } from "ente-base/context";
import { Notification } from "ente-new/photos/components/Notification";
import { t } from "i18next";

export interface FilesDownloadProgressAttributes {
    id: number;
    success: number;
    failed: number;
    total: number;
    folderName: string;
    collectionID: number;
    isHidden: boolean;
    downloadDirPath: string;
    canceller: AbortController;
}

interface FilesDownloadProgressProps {
    attributesList: FilesDownloadProgressAttributes[];
    setAttributesList: (value: FilesDownloadProgressAttributes[]) => void;
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

export const isFilesDownloadStarted = (
    attributes: FilesDownloadProgressAttributes,
) => {
    return attributes && attributes.total > 0;
};

export const isFilesDownloadCompleted = (
    attributes: FilesDownloadProgressAttributes,
) => {
    return (
        attributes &&
        attributes.success + attributes.failed === attributes.total
    );
};

const isFilesDownloadCompletedWithErrors = (
    attributes: FilesDownloadProgressAttributes,
) => {
    return (
        attributes &&
        attributes.failed > 0 &&
        isFilesDownloadCompleted(attributes)
    );
};

export const isFilesDownloadCancelled = (
    attributes: FilesDownloadProgressAttributes,
) => {
    return attributes?.canceller?.signal?.aborted;
};

export const FilesDownloadProgress: React.FC<FilesDownloadProgressProps> = ({
    attributesList,
    setAttributesList,
    onShowHiddenSection,
    onShowCollection,
}) => {
    const { showMiniDialog } = useBaseContext();

    if (!attributesList) {
        return <></>;
    }

    const onClose = (id: number) => {
        setAttributesList(attributesList.filter((attr) => attr.id !== id));
    };

    const confirmCancelDownload = (
        attributes: FilesDownloadProgressAttributes,
    ) => {
        showMiniDialog({
            title: t("stop_downloads_title"),
            message: t("stop_downloads_message"),
            continue: {
                text: t("yes_stop_downloads"),
                color: "critical",
                action: () => {
                    attributes?.canceller.abort();
                    onClose(attributes.id);
                },
            },
            cancel: t("no"),
        });
    };

    const handleClose = (attributes: FilesDownloadProgressAttributes) => () => {
        if (isFilesDownloadCompleted(attributes)) {
            onClose(attributes.id);
        } else {
            confirmCancelDownload(attributes);
        }
    };

    const createHandleOnClick =
        (id: number, onShowCollection: (collectionID: number) => void) =>
        () => {
            const attributes = attributesList.find((attr) => attr.id === id);
            const electron = globalThis.electron;
            if (electron) {
                electron.openDirectory(attributes.downloadDirPath);
            } else if (onShowCollection) {
                if (attributes.isHidden) {
                    void onShowHiddenSection().then(() => {
                        onShowCollection(attributes.collectionID);
                    });
                } else {
                    onShowCollection(attributes.collectionID);
                }
            }
        };

    const notifications: React.ReactNode[] = [];
    let visibleIndex = 0;
    for (const attributes of attributesList) {
        // Skip attempted downloads of empty albums, which had no effect.
        if (!isFilesDownloadStarted(attributes)) continue;

        const index = visibleIndex++;
        notifications.push(
            <Notification
                key={attributes.id}
                horizontal="left"
                sx={{ "&&": { bottom: `${index * 80 + 20}px` } }}
                open={isFilesDownloadStarted(attributes)}
                onClose={handleClose(attributes)}
                keepOpenOnClick
                attributes={{
                    color: isFilesDownloadCompletedWithErrors(attributes)
                        ? "critical"
                        : "secondary",
                    title: isFilesDownloadCompletedWithErrors(attributes)
                        ? t("download_failed")
                        : isFilesDownloadCompleted(attributes)
                          ? t("download_complete")
                          : t("downloading_album", {
                                name: attributes.folderName,
                            }),
                    caption: isFilesDownloadCompleted(attributes)
                        ? attributes.folderName
                        : t("download_progress", {
                              count: attributes.success + attributes.failed,
                              total: attributes.total,
                          }),
                    onClick: onShowCollection
                        ? createHandleOnClick(attributes.id, onShowCollection)
                        : undefined,
                }}
            />,
        );
    }

    return notifications;
};
