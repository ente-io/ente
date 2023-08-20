import Notification from 'components/Notification';
import { HIDDEN_SECTION } from 'constants/collection';
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
    downloadPath?: string;
    canceller?: AbortController;
}

interface CollectionDownloadProgressProps {
    isOpen: boolean;
    onClose: () => void;
    attributes: CollectionDownloadProgressAttributes;
}

export const CollectionDownloadProgress: React.FC<CollectionDownloadProgressProps> =
    ({ isOpen, onClose, attributes }) => {
        const appContext = useContext(AppContext);
        const galleryContext = useContext(GalleryContext);

        if (!attributes) {
            return <></>;
        }
        const confirmCancelUpload = () => {
            appContext.setDialogMessage({
                title: t('STOP_DOWNLOADS_HEADER'),
                content: t('STOP_ALL_DOWNLOADS_MESSAGE'),
                proceed: {
                    text: t('YES_STOP_DOWNLOADS'),
                    variant: 'critical',
                    action: () => {
                        attributes?.canceller.abort();
                        onClose();
                    },
                },
                close: {
                    text: t('NO'),
                    variant: 'secondary',
                    action: () => {},
                },
            });
        };

        const downloadCompleted =
            attributes.success + attributes.failed === attributes.total;

        const downloadCompletedWithErrors =
            attributes.failed > 0 && downloadCompleted;

        const handleClose = () => {
            if (downloadCompleted) {
                onClose();
            } else {
                confirmCancelUpload();
            }
        };

        const handleOnClick = () => {
            if (isElectron()) {
                ElectronService.openDirectory(attributes.downloadPath);
            } else {
                if (attributes.collectionID === HIDDEN_SECTION) {
                    galleryContext.authenticateUser(() => {
                        galleryContext.setActiveCollectionID(HIDDEN_SECTION);
                    });
                } else {
                    galleryContext.setActiveCollectionID(
                        attributes.collectionID
                    );
                }
            }
        };

        return (
            <Notification
                open={isOpen}
                onClose={handleClose}
                keepOpenOnClick
                attributes={{
                    variant: 'secondary',
                    title: downloadCompletedWithErrors
                        ? t('DOWNLOAD_FAILED')
                        : downloadCompleted
                        ? t(`DOWNLOAD_COMPLETE`)
                        : t(`DOWNLOADING`),
                    caption: downloadCompleted
                        ? attributes.collectionName
                        : `${attributes.success} / ${attributes.total} items`,
                    onClick: handleOnClick,
                }}
            />
        );
    };
