import { useBaseContext } from "@/base/context";
import { Notification } from "@/new/photos/components/Notification";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { useContext } from "react";

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

export const isFilesDownloadCompletedWithErrors = (
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
}) => {
    const { showMiniDialog } = useBaseContext();
    const galleryContext = useContext(GalleryContext);

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

    const handleOnClick = (id: number) => () => {
        const attributes = attributesList.find((attr) => attr.id === id);
        const electron = globalThis.electron;
        if (electron) {
            electron.openDirectory(attributes.downloadDirPath);
        } else {
            if (attributes.isHidden) {
                galleryContext.openHiddenSection(() => {
                    galleryContext.setActiveCollectionID(
                        attributes.collectionID,
                    );
                });
            } else {
                galleryContext.setActiveCollectionID(attributes.collectionID);
            }
        }
    };

    return (
        <>
            {attributesList.map((attributes, index) => (
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
                        onClick: handleOnClick(attributes.id),
                    }}
                />
            ))}
        </>
    );
};
