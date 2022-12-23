export const ServerErrorCodes = {
    SESSION_EXPIRED: '401',
    NO_ACTIVE_SUBSCRIPTION: '402',
    FORBIDDEN: '403',
    STORAGE_LIMIT_EXCEEDED: '426',
    FILE_TOO_LARGE: '413',
    TOKEN_EXPIRED: '410',
    TOO_MANY_REQUEST: '429',
    BAD_REQUEST: '400',
    PAYMENT_REQUIRED: '402',
    NOT_FOUND: '404',
};

export enum CustomError {
    SUBSCRIPTION_VERIFICATION_ERROR = 'Subscription verification failed',
    THUMBNAIL_GENERATION_FAILED = 'thumbnail generation failed',
    VIDEO_PLAYBACK_FAILED = 'video playback failed',
    ETAG_MISSING = 'no header/etag present in response body',
    KEY_MISSING = 'encrypted key missing from localStorage',
    FAILED_TO_LOAD_WEB_WORKER = 'failed to load web worker',
    CHUNK_MORE_THAN_EXPECTED = 'chunks more than expected',
    CHUNK_LESS_THAN_EXPECTED = 'chunks less than expected',
    UNSUPPORTED_FILE_FORMAT = 'unsupported file formats',
    FILE_TOO_LARGE = 'file too large',
    SUBSCRIPTION_EXPIRED = 'subscription expired',
    STORAGE_QUOTA_EXCEEDED = 'storage quota exceeded',
    SESSION_EXPIRED = 'session expired',
    TYPE_DETECTION_FAILED = 'type detection failed',
    SIGNUP_FAILED = 'signup failed',
    FAV_COLLECTION_MISSING = 'favorite collection missing',
    INVALID_COLLECTION_OPERATION = 'invalid collection operation',
    WAIT_TIME_EXCEEDED = 'thumbnail generation wait time exceeded',
    REQUEST_CANCELLED = 'request canceled',
    REQUEST_FAILED = 'request failed',
    TOKEN_EXPIRED = 'token expired',
    TOKEN_MISSING = 'token missing',
    TOO_MANY_REQUESTS = 'too many requests',
    BAD_REQUEST = 'bad request',
    SUBSCRIPTION_NEEDED = 'subscription not present',
    NOT_FOUND = 'not found ',
    NO_METADATA = 'no metadata',
    TOO_LARGE_LIVE_PHOTO_ASSETS = 'too large live photo assets',
    NOT_A_DATE = 'not a date',
    FILE_ID_NOT_FOUND = 'file with id not found',
    WEAK_DEVICE = 'password decryption failed on the device',
    INCORRECT_PASSWORD = 'incorrect password',
    UPLOAD_CANCELLED = 'upload cancelled',
    REQUEST_TIMEOUT = 'request taking too long',
    HIDDEN_COLLECTION_SYNC_FILE_ATTEMPTED = 'hidden collection sync file attempted',
    UNKNOWN_ERROR = 'Something went wrong, please try again',
}

function parseUploadErrorCodes(error) {
    let parsedMessage = null;
    if (error?.status) {
        const errorCode = error.status.toString();
        switch (errorCode) {
            case ServerErrorCodes.NO_ACTIVE_SUBSCRIPTION:
                parsedMessage = CustomError.SUBSCRIPTION_EXPIRED;
                break;
            case ServerErrorCodes.STORAGE_LIMIT_EXCEEDED:
                parsedMessage = CustomError.STORAGE_QUOTA_EXCEEDED;
                break;
            case ServerErrorCodes.SESSION_EXPIRED:
                parsedMessage = CustomError.SESSION_EXPIRED;
                break;
            case ServerErrorCodes.FILE_TOO_LARGE:
                parsedMessage = CustomError.FILE_TOO_LARGE;
                break;
            default:
                parsedMessage = `${CustomError.UNKNOWN_ERROR} statusCode:${errorCode}`;
        }
    } else {
        parsedMessage = error.message;
    }
    return new Error(parsedMessage);
}

export function handleUploadError(error): Error {
    const parsedError = parseUploadErrorCodes(error);

    // breaking errors
    switch (parsedError.message) {
        case CustomError.SUBSCRIPTION_EXPIRED:
        case CustomError.STORAGE_QUOTA_EXCEEDED:
        case CustomError.SESSION_EXPIRED:
        case CustomError.UPLOAD_CANCELLED:
            throw parsedError;
    }
    return parsedError;
}

export function errorWithContext(originalError: Error, context: string) {
    const errorWithContext = new Error(context);
    errorWithContext.stack =
        errorWithContext.stack.split('\n').slice(2, 4).join('\n') +
        '\n' +
        originalError.stack;
    return errorWithContext;
}

export const parseSharingErrorCodes = (error) => {
    let parsedMessage = null;
    if (error?.status) {
        const errorCode = error.status.toString();
        switch (errorCode) {
            case ServerErrorCodes.BAD_REQUEST:
                parsedMessage = CustomError.BAD_REQUEST;
                break;
            case ServerErrorCodes.PAYMENT_REQUIRED:
                parsedMessage = CustomError.SUBSCRIPTION_NEEDED;
                break;
            case ServerErrorCodes.NOT_FOUND:
                parsedMessage = CustomError.NOT_FOUND;
                break;
            case ServerErrorCodes.SESSION_EXPIRED:
            case ServerErrorCodes.TOKEN_EXPIRED:
                parsedMessage = CustomError.TOKEN_EXPIRED;
                break;
            case ServerErrorCodes.TOO_MANY_REQUEST:
                parsedMessage = CustomError.TOO_MANY_REQUESTS;
                break;
            default:
                parsedMessage = `${CustomError.UNKNOWN_ERROR} statusCode:${errorCode}`;
        }
    } else {
        parsedMessage = error.message;
    }
    return new Error(parsedMessage);
};
