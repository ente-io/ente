import { DialogBoxAttributes } from 'types/dialogBox';
import { downloadApp } from 'utils/common';
import constants from 'utils/strings/constants';

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
