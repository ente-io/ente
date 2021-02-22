export const errorCodes = {
    ERR_STORAGE_LIMIT_EXCEEDED: '426',
    ERR_NO_ACTIVE_SUBSCRIPTION: '402',
    ERR_NO_INTERNET_CONNECTION: '1',
};

export function ErrorHandler(error) {
    if (
        error.response?.status.toString() ==
            errorCodes.ERR_STORAGE_LIMIT_EXCEEDED ||
        error.response?.status.toString() ==
            errorCodes.ERR_NO_ACTIVE_SUBSCRIPTION
    ) {
        throw new Error(error.response.status);
    } else {
        return;
    }
}
