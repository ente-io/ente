import Notification from 'components/Notification';
import { t } from 'i18next';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import ElectronService from 'services/electron/common';

export interface CollectionDownloadProgressAttributes {
    success: number;
    failed: number;
    total: number;
    collectionName: string;
    collectionDownloadPath: string;
    cancelDownload: () => void;
}

interface CollectionDownloadProgressProps {
    isOpen: boolean;
    onClose: () => void;
    attributes: CollectionDownloadProgressAttributes;
}

export const CollectionDownloadProgress: React.FC<CollectionDownloadProgressProps> =
    ({ isOpen, onClose, attributes }) => {
        const appContext = useContext(AppContext);

        if (!attributes) {
            return <></>;
        }
        const confirmCancelUpload = () => {
            appContext.setDialogMessage({
                title: t('STOP_UPLOADS_HEADER'),
                content: t('STOP_ALL_UPLOADS_MESSAGE'),
                proceed: {
                    text: t('YES_STOP_UPLOADS'),
                    variant: 'critical',
                    action: attributes?.cancelDownload,
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

        return (
            <Notification
                open={isOpen}
                onClose={handleClose}
                attributes={{
                    variant: 'secondary',
                    title: downloadCompletedWithErrors
                        ? `Download failed`
                        : downloadCompleted
                        ? `Download complete`
                        : `Downloading`,
                    caption: downloadCompleted
                        ? attributes.collectionName
                        : `${attributes.success} / ${attributes.total} items`,
                    onClick: () => {
                        ElectronService.openDirectory(
                            attributes.collectionDownloadPath
                        );
                    },
                }}
            />
        );
    };
