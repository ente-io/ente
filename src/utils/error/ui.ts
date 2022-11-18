import constants from 'utils/strings/constants';
import { parseSharingErrorCodes, CustomError } from '.';

export const handleSharingErrors = (error) => {
    const parsedError = parseSharingErrorCodes(error);
    let errorMessage = '';
    switch (parsedError.message) {
        case CustomError.BAD_REQUEST:
            errorMessage = constants.SHARING_BAD_REQUEST_ERROR;
            break;
        case CustomError.SUBSCRIPTION_NEEDED:
            errorMessage = constants.SHARING_DISABLED_FOR_FREE_ACCOUNTS;
            break;
        case CustomError.NOT_FOUND:
            errorMessage = constants.USER_DOES_NOT_EXIST;
            break;
        default:
            errorMessage = parsedError.message;
    }
    return errorMessage;
};

export function checkConnectivity() {
    if (navigator.onLine) {
        return true;
    }
    throw new Error(constants.NO_INTERNET_CONNECTION);
}
