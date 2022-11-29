import React from 'react';
import AutoAwesomeOutlinedIcon from '@mui/icons-material/AutoAwesomeOutlined';
import { DialogBoxAttributes } from 'types/dialogBox';
import { downloadApp } from 'utils/common';
import constants from 'utils/strings/constants';
import ElectronUpdateService from 'services/electron/update';
import { AppUpdateInfo } from 'types/electron';
export const getDownloadAppMessage = (): DialogBoxAttributes => {
    return {
        title: constants.DOWNLOAD_APP,
        content: constants.DOWNLOAD_APP_MESSAGE,

        proceed: {
            text: constants.DOWNLOAD,
            action: downloadApp,
            variant: 'accent',
        },
        close: {
            text: constants.CLOSE,
        },
    };
};

export const getTrashFilesMessage = (
    deleteFileHelper
): DialogBoxAttributes => ({
    title: constants.TRASH_FILES_TITLE,
    content: constants.TRASH_FILES_MESSAGE,
    proceed: {
        action: deleteFileHelper,
        text: constants.MOVE_TO_TRASH,
        variant: 'danger',
    },
    close: { text: constants.CANCEL },
});

export const getTrashFileMessage = (deleteFileHelper): DialogBoxAttributes => ({
    title: constants.TRASH_FILE_TITLE,
    content: constants.TRASH_FILE_MESSAGE,
    proceed: {
        action: deleteFileHelper,
        text: constants.MOVE_TO_TRASH,
        variant: 'danger',
    },
    close: { text: constants.CANCEL },
});

export const getUpdateReadyToInstallMessage = (
    updateInfo: AppUpdateInfo
): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: constants.UPDATE_AVAILABLE,
    content: constants.UPDATE_INSTALLABLE_MESSAGE,
    close: {
        text: constants.INSTALL_ON_NEXT_LAUNCH,
        variant: 'secondary',
        action: () => ElectronUpdateService.updateAndRestart(),
    },
    proceed: {
        action: () =>
            ElectronUpdateService.muteUpdateNotification(updateInfo.version),
        text: constants.INSTALL_NOW,
        variant: 'accent',
    },
});

export const getUpdateAvailableForDownloadMessage = (
    updateInfo: AppUpdateInfo
): DialogBoxAttributes => ({
    icon: <AutoAwesomeOutlinedIcon />,
    title: constants.UPDATE_AVAILABLE,
    content: constants.UPDATE_AVAILABLE_MESSAGE,
    close: {
        text: constants.IGNORE_THIS_VERSION,
        variant: 'secondary',
        action: () => ElectronUpdateService.skipAppUpdate(updateInfo.version),
    },
    proceed: {
        action: downloadApp,
        text: constants.DOWNLOAD_AND_INSTALL,
        variant: 'accent',
    },
});
