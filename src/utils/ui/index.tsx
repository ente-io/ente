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
