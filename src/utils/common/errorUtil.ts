import constants from 'utils/strings/constants';

export const errorCodes = {
    ERR_STORAGE_LIMIT_EXCEEDED: '426',
    ERR_NO_ACTIVE_SUBSCRIPTION: '402',
    ERR_NO_INTERNET_CONNECTION: '1',
    ERR_SESSION_EXPIRED: '401',
};

export function ErrorHandler(error) {
    if (
        error.response?.status.toString() ==
            errorCodes.ERR_STORAGE_LIMIT_EXCEEDED ||
        error.response?.status.toString() ==
            errorCodes.ERR_NO_ACTIVE_SUBSCRIPTION ||
        error.response?.status.toString() == errorCodes.ERR_SESSION_EXPIRED
    ) {
        throw new Error(error.response.status);
    } else {
        return;
    }
}

export function ErrorBannerMessage(bannerErrorCode) {
    let errorMessage;
    switch (bannerErrorCode) {
        case errorCodes.ERR_NO_ACTIVE_SUBSCRIPTION:
            errorMessage = constants.SUBSCRIPTION_EXPIRED;
            break;
        case errorCodes.ERR_STORAGE_LIMIT_EXCEEDED:
            errorMessage = constants.STORAGE_QUOTA_EXCEEDED;
            break;
        case errorCodes.ERR_NO_INTERNET_CONNECTION:
            errorMessage = constants.NO_INTERNET_CONNECTION;
            break;
        default:
            errorMessage = `Unknown Error Code - ${bannerErrorCode} Encountered`;
    }
    return errorMessage;
}
