import React from 'react';
import AutoAwesomeOutlinedIcon from '@mui/icons-material/AutoAwesomeOutlined';
import { DialogBoxAttributes } from 'types/dialogBox';
import { downloadApp } from 'utils/common';
import { t } from 'i18next';

import ElectronUpdateService from 'services/electron/update';
import { AppUpdateInfo } from 'types/electron';
import InfoOutlined from '@mui/icons-material/InfoRounded';
import { Trans } from 'react-i18next';
export const getDownloadAppMessage = (): DialogBoxAttributes => {
    return {
        title: t('DOWNLOAD_APP'),
        content: t('DOWNLOAD_APP_MESSAGE'),

        proceed: {
            text: t('DOWNLOAD'),
            action: downloadApp,
            variant: 'accent',
        },
        close: {
            text: t('CLOSE'),
        },
    };
};

export const getTrashFilesMessage = (
    deleteFileHelper
): DialogBoxAttributes => ({
    title: t('TRASH_FILES_TITLE'),
    content: t('TRASH_FILES_MESSAGE'),
    proceed: {
        action: deleteFileHelper,
        text: t('MOVE_TO_TRASH'),
        variant: 'danger',
    },
    close: { text: t('CANCEL') },
});

export const getTrashFileMessage = (deleteFileHelper): DialogBoxAttributes => ({
    title: t('TRASH_FILE_TITLE'),
    content: t('TRASH_FILE_MESSAGE'),
    proceed: {
        action: deleteFileHelper,
        text: t('MOVE_TO_TRASH'),
        variant: 'danger',
    },
    close: { text: t('CANCEL') },
});

export const getUpdateReadyToInstallMessage = (
    updateInfo: AppUpdateInfo
): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: t('UPDATE_AVAILABLE'),
    content: t('UPDATE_INSTALLABLE_MESSAGE'),
    close: {
        text: t('INSTALL_ON_NEXT_LAUNCH'),
        variant: 'secondary',
        action: () => ElectronUpdateService.updateAndRestart(),
    },
    proceed: {
        action: () =>
            ElectronUpdateService.muteUpdateNotification(updateInfo.version),
        text: t('INSTALL_NOW'),
        variant: 'accent',
    },
});

export const getUpdateAvailableForDownloadMessage = (
    updateInfo: AppUpdateInfo
): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: t('UPDATE_AVAILABLE'),
    content: t('UPDATE_AVAILABLE_MESSAGE'),
    close: {
        text: t('IGNORE_THIS_VERSION'),
        variant: 'secondary',
        action: () => ElectronUpdateService.skipAppUpdate(updateInfo.version),
    },
    proceed: {
        action: downloadApp,
        text: t('DOWNLOAD_AND_INSTALL'),
        variant: 'accent',
    },
});

export const getRootLevelFileWithFolderNotAllowMessage =
    (): DialogBoxAttributes => ({
        icon: <InfoOutlined />,
        title: t('ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED'),
        content: (
            <Trans i18nKey={'ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED_MESSAGE'}>
                <p>
                    You have dragged and dropped a mixture of files and folders.
                </p>
                <p>
                    Please provide either only files, or only folders when
                    selecting option to create separate albums
                </p>
            </Trans>
        ),
        close: {},
    });

export const getExportDirectoryDoesNotExistMessage =
    (): DialogBoxAttributes => ({
        title: t('EXPORT_DIRECTORY_DOES_NOT_EXIST'),
        content: (
            <Trans i18nKey={'EXPORT_DIRECTORY_DOES_NOT_EXIST_MESSAGE'}>
                <p>The export directory you have selected does not exist.</p>
                <p> Please select a valid directory.</p>
            </Trans>
        ),
        close: {},
    });
