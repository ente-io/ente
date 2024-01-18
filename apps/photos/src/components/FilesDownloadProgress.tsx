import Notification from 'components/Notification';
import { t } from 'i18next';
import isElectron from 'is-electron';
import { AppContext } from 'pages/_app';
import { GalleryContext } from 'pages/gallery';
import { useContext } from 'react';
import ElectronAPIs from '@ente/shared/electron';

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
    attributes: FilesDownloadProgressAttributes
) => {
    return attributes && attributes.total > 0;
};

export const isFilesDownloadCompleted = (
    attributes: FilesDownloadProgressAttributes
) => {
    return (
        attributes &&
        attributes.success + attributes.failed === attributes.total
    );
};

export const isFilesDownloadCompletedWithErrors = (
    attributes: FilesDownloadProgressAttributes
) => {
    return (
        attributes &&
        attributes.failed > 0 &&
        isFilesDownloadCompleted(attributes)
    );
};

export const isFilesDownloadCancelled = (
    attributes: FilesDownloadProgressAttributes
) => {
    return attributes && attributes.canceller?.signal?.aborted;
};

export const FilesDownloadProgress: React.FC<FilesDownloadProgressProps> = ({
    attributesList,
    setAttributesList,
}) => {
    const appContext = useContext(AppContext);
    const galleryContext = useContext(GalleryContext);

    if (!attributesList) {
        return <></>;
    }

    const onClose = (id: number) => {
        setAttributesList(attributesList.filter((attr) => attr.id !== id));
    };

    const confirmCancelUpload = (
        attributes: FilesDownloadProgressAttributes
    ) => {
        appContext.setDialogMessage({
            title: t('STOP_DOWNLOADS_HEADER'),
            content: t('STOP_ALL_DOWNLOADS_MESSAGE'),
            proceed: {
                text: t('YES_STOP_DOWNLOADS'),
                variant: 'critical',
                action: () => {
                    attributes?.canceller.abort();
                    onClose(attributes.id);
                },
            },
            close: {
                text: t('NO'),
                variant: 'secondary',
                action: () => {},
            },
        });
    };

    const handleClose = (attributes: FilesDownloadProgressAttributes) => () => {
        if (isFilesDownloadCompleted(attributes)) {
            onClose(attributes.id);
        } else {
            confirmCancelUpload(attributes);
        }
    };

    const handleOnClick = (id: number) => () => {
        const attributes = attributesList.find((attr) => attr.id === id);
        if (isElectron()) {
            ElectronAPIs.openDirectory(attributes.downloadDirPath);
        } else {
            if (attributes.isHidden) {
                galleryContext.openHiddenSection(() => {
                    galleryContext.setActiveCollectionID(
                        attributes.collectionID
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
                    sx={{
                        '&&': { bottom: `${index * 80 + 20}px` },
                        zIndex: 1600,
                    }}
                    open={isFilesDownloadStarted(attributes)}
                    onClose={handleClose(attributes)}
                    keepOpenOnClick
                    attributes={{
                        variant: isFilesDownloadCompletedWithErrors(attributes)
                            ? 'critical'
                            : 'secondary',
                        title: isFilesDownloadCompletedWithErrors(attributes)
                            ? t('DOWNLOAD_FAILED')
                            : isFilesDownloadCompleted(attributes)
                            ? t(`DOWNLOAD_COMPLETE`)
                            : t('DOWNLOADING_COLLECTION', {
                                  name: attributes.folderName,
                              }),
                        caption: isFilesDownloadCompleted(attributes)
                            ? attributes.folderName
                            : t('DOWNLOAD_PROGRESS', {
                                  progress: {
                                      current:
                                          attributes.success +
                                          attributes.failed,
                                      total: attributes.total,
                                  },
                              }),
                        onClick: handleOnClick(attributes.id),
                    }}
                />
            ))}
        </>
    );
};
