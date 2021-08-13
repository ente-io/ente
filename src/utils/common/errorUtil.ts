import constants from 'utils/strings/constants';

export const ServerErrorCodes = {
    SESSION_EXPIRED: '401',
    NO_ACTIVE_SUBSCRIPTION: '402',
    FORBIDDEN: '403',
    STORAGE_LIMIT_EXCEEDED: '426',
};

export const CustomError = {
    SUBSCRIPTION_VERIFICATION_ERROR: 'Subscription verification failed',
    THUMBNAIL_GENERATION_FAILED: 'thumbnail generation failed',
    VIDEO_PLAYBACK_FAILED: 'video playback failed',
    ETAG_MISSING: 'no header/etag present in response body',
    KEY_MISSING: 'encrypted key missing from localStorage',
    FAILED_TO_LOAD_WEB_WORKER: 'failed to load web worker',
    CHUNK_MORE_THAN_EXPECTED: 'chunks more than expected',
};

export function parseError(error) {
    let parsedMessage = null;
    if (error?.status) {
        const errorCode = error.status.toString();
        switch (errorCode) {
            case ServerErrorCodes.NO_ACTIVE_SUBSCRIPTION:
                parsedMessage = constants.SUBSCRIPTION_EXPIRED;
                break;
            case ServerErrorCodes.STORAGE_LIMIT_EXCEEDED:
                parsedMessage = constants.STORAGE_QUOTA_EXCEEDED;
                break;
            case ServerErrorCodes.SESSION_EXPIRED:
                parsedMessage = constants.SESSION_EXPIRED_MESSAGE;
                break;
        }
    }
    if (parsedMessage) {
        return { parsedError: new Error(parsedMessage), parsed: true };
    } else {
        return {
            parsedError: new Error(`${constants.UNKNOWN_ERROR} ${error}`),
            parsed: false,
        };
    }
}

export function handleError(error) {
    const { parsedError, parsed } = parseError(error);
    if (parsed) {
        throw parsedError;
    } else {
        // swallow error don't break the caller flow
    }
}
