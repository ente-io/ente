import Notification from 'components/Notification';
import { t } from 'i18next';
import isElectron from 'is-electron';
import { AppContext } from 'pages/_app';
import { GalleryContext } from 'pages/gallery';
import { useContext } from 'react';
import ElectronService from 'services/electron/common';

export interface CollectionDownloadProgressAttributes {
    success: number;
    failed: number;
    total: number;
    collectionName: string;
    collectionID: number;
    isHidden: boolean;
    downloadDirPath: string;
    canceller: AbortController;
}

interface CollectionDownloadProgressProps {
    attributesList: CollectionDownloadProgressAttributes[];
    setAttributesList: (value: CollectionDownloadProgressAttributes[]) => void;
}

export const isCollectionDownloadCompleted = (
    attributes: CollectionDownloadProgressAttributes
) => {
    return (
        attributes &&
        attributes.success + attributes.failed === attributes.total
    );
};

export const isCollectionDownloadCompletedWithErrors = (
    attributes: CollectionDownloadProgressAttributes
) => {
    return (
        attributes &&
        attributes.failed > 0 &&
        isCollectionDownloadCompleted(attributes)
    );
};

export const isCollectionDownloadCancelled = (
    attributes: CollectionDownloadProgressAttributes
) => {
    return attributes && attributes.canceller?.signal?.aborted;
};

export const CollectionDownloadProgress: React.FC<CollectionDownloadProgressProps> =
    ({ attributesList, setAttributesList }) => {
        const appContext = useContext(AppContext);
        const galleryContext = useContext(GalleryContext);

        if (!attributesList) {
            return <></>;
        }

        const onClose = (collectionID: number) => {
            setAttributesList(
                attributesList.filter(
                    (attr) => attr.collectionID !== collectionID
                )
            );
        };

        const confirmCancelUpload = (
            attributes: CollectionDownloadProgressAttributes
        ) => {
            appContext.setDialogMessage({
                title: t('STOP_DOWNLOADS_HEADER'),
                content: t('STOP_ALL_DOWNLOADS_MESSAGE'),
                proceed: {
                    text: t('YES_STOP_DOWNLOADS'),
                    variant: 'critical',
                    action: () => {
                        attributes?.canceller.abort();
                        onClose(attributes.collectionID);
                    },
                },
                close: {
                    text: t('NO'),
                    variant: 'secondary',
                    action: () => {},
                },
            });
        };

        const handleClose =
            (attributes: CollectionDownloadProgressAttributes) => () => {
                if (isCollectionDownloadCompleted(attributes)) {
                    onClose(attributes.collectionID);
                } else {
                    confirmCancelUpload(attributes);
                }
            };

        const handleOnClick = (collectionID: number) => () => {
            const attributes = attributesList.find(
                (attr) => attr.collectionID === collectionID
            );
            if (isElectron()) {
                ElectronService.openDirectory(attributes.downloadDirPath);
            } else {
                if (attributes.isHidden) {
                    galleryContext.openHiddenSection(() => {
                        galleryContext.setActiveCollectionID(
                            attributes.collectionID
                        );
                    });
                } else {
                    galleryContext.setActiveCollectionID(
                        attributes.collectionID
                    );
                }
            }
        };

        return (
            <>
                {attributesList.map((attributes, index) => (
                    <Notification
                        key={attributes.collectionID}
                        horizontal="left"
                        sx={{ '&&': { bottom: `${index * 80 + 20}px` } }}
                        open
                        onClose={handleClose(attributes)}
                        keepOpenOnClick
                        attributes={{
                            variant: isCollectionDownloadCompletedWithErrors(
                                attributes
                            )
                                ? 'critical'
                                : 'secondary',
                            title: isCollectionDownloadCompletedWithErrors(
                                attributes
                            )
                                ? t('DOWNLOAD_FAILED')
                                : isCollectionDownloadCompleted(attributes)
                                ? t(`DOWNLOAD_COMPLETE`)
                                : t('DOWNLOADING_COLLECTION', {
                                      name: attributes.collectionName,
                                  }),
                            caption: isCollectionDownloadCompleted(attributes)
                                ? attributes.collectionName
                                : t('DOWNLOAD_PROGRESS', {
                                      progress: {
                                          current:
                                              attributes.success +
                                              attributes.failed,
                                          total: attributes.total,
                                      },
                                  }),
                            onClick: handleOnClick(attributes.collectionID),
                        }}
                    />
                ))}
            </>
        );
    };
