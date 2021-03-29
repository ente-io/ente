import { logoutUser } from 'services/userService';
import constants from 'utils/strings/constants';

export const errorCodes = {
    ERR_STORAGE_LIMIT_EXCEEDED: '426',
    ERR_NO_ACTIVE_SUBSCRIPTION: '402',
    ERR_NO_INTERNET_CONNECTION: '1',
    ERR_SESSION_EXPIRED: '401',
};

export function ErrorHandler(error) {
    const errorCode = error.response?.status.toString();
    let errorMessage;
    switch (errorCode) {
        case errorCodes.ERR_NO_ACTIVE_SUBSCRIPTION:
            errorMessage = constants.SUBSCRIPTION_EXPIRED;
            break;
        case errorCodes.ERR_STORAGE_LIMIT_EXCEEDED:
            errorMessage = constants.STORAGE_QUOTA_EXCEEDED;
            break;
        case errorCodes.ERR_NO_INTERNET_CONNECTION:
            errorMessage = constants.NO_INTERNET_CONNECTION;
            break;
        case errorCodes.ERR_SESSION_EXPIRED:
            errorMessage = constants.SESSION_EXPIRED;
            setTimeout(logoutUser, 5000);
            break;
        default:
            errorMessage = `Unknown Error - ${error} Encountered`;
    }
    throw new Error(errorMessage);
}
