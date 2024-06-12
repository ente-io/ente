import { HttpStatusCode } from "axios";

export interface ApiErrorResponse {
    code: string;
    message: string;
}

export class ApiError extends Error {
    httpStatusCode: number;
    errCode: string;

    constructor(message: string, errCode: string, httpStatus: number) {
        super(message);
        this.name = "ApiError";
        this.errCode = errCode;
        this.httpStatusCode = httpStatus;
    }
}

export function isApiErrorResponse(object: any): object is ApiErrorResponse {
    return object && "code" in object && "message" in object;
}

export const CustomError = {
    VIDEO_PLAYBACK_FAILED: "video playback failed",
    ETAG_MISSING: "no header/etag present in response body",
    KEY_MISSING: "encrypted key missing from localStorage",
    FAILED_TO_LOAD_WEB_WORKER: "failed to load web worker",
    UNSUPPORTED_FILE_FORMAT: "unsupported file format",
    FILE_TOO_LARGE: "file too large",
    SUBSCRIPTION_EXPIRED: "subscription expired",
    STORAGE_QUOTA_EXCEEDED: "storage quota exceeded",
    SESSION_EXPIRED: "session expired",
    INVALID_MIME_TYPE: (type: string) => `invalid mime type -${type}`,
    SIGNUP_FAILED: "signup failed",
    FAV_COLLECTION_MISSING: "favorite collection missing",
    INVALID_COLLECTION_OPERATION: "invalid collection operation",
    TO_MOVE_FILES_FROM_MULTIPLE_COLLECTIONS:
        "to move files from multiple collections",
    REQUEST_CANCELLED: "request canceled",
    REQUEST_FAILED: "request failed",
    TOKEN_EXPIRED: "token expired",
    TOKEN_MISSING: "token missing",
    TOO_MANY_REQUESTS: "too many requests",
    BAD_REQUEST: "bad request",
    SUBSCRIPTION_NEEDED: "subscription not present",
    NOT_FOUND: "not found ",
    NO_METADATA: "no metadata",
    FILE_ID_NOT_FOUND: "file with id not found",
    WEAK_DEVICE: "password decryption failed on the device",
    INCORRECT_PASSWORD: "incorrect password",
    UPLOAD_CANCELLED: "upload cancelled",
    REQUEST_TIMEOUT: "request taking too long",
    HIDDEN_COLLECTION_SYNC_FILE_ATTEMPTED:
        "hidden collection sync file attempted",
    UNKNOWN_ERROR: "Something went wrong, please try again",
    WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED:
        "Windows native image processing is not supported",
    NETWORK_ERROR: "Network Error",
    NOT_FILE_OWNER: "not file owner",
    UPDATE_EXPORTED_RECORD_FAILED: "update file exported record failed",
    EXPORT_STOPPED: "export stopped",
    NO_EXPORT_FOLDER_SELECTED: "no export folder selected",
    EXPORT_FOLDER_DOES_NOT_EXIST: "export folder does not exist",
    AUTH_KEY_NOT_FOUND: "auth key not found",
    EXIF_DATA_NOT_FOUND: "exif data not found",
    SELECT_FOLDER_ABORTED: "select folder aborted",
    PROCESSING_FAILED: "processing failed",
    EXPORT_RECORD_JSON_PARSING_FAILED: "export record json parsing failed",
    TWO_FACTOR_ENABLED: "two factor enabled",
    CLIENT_ERROR: "client error",
    ServerError: "server error",
    FILE_NOT_FOUND: "file not found",
    UNSUPPORTED_PLATFORM: "Unsupported platform",
    UPDATE_URL_FILE_ID_MISMATCH: "update url file id mismatch",
    URL_ALREADY_SET: "url already set",
    FILE_CONVERSION_FAILED: "file conversion failed",
};

export function handleUploadError(error: any): Error {
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

export function parseUploadErrorCodes(error: any) {
    let parsedMessage = null;
    if (error instanceof ApiError) {
        switch (error.httpStatusCode) {
            case HttpStatusCode.PaymentRequired:
                parsedMessage = CustomError.SUBSCRIPTION_EXPIRED;
                break;
            case HttpStatusCode.UpgradeRequired:
                parsedMessage = CustomError.STORAGE_QUOTA_EXCEEDED;
                break;
            case HttpStatusCode.Unauthorized:
                parsedMessage = CustomError.SESSION_EXPIRED;
                break;
            case HttpStatusCode.PayloadTooLarge:
                parsedMessage = CustomError.FILE_TOO_LARGE;
                break;
            default:
                parsedMessage = `${CustomError.UNKNOWN_ERROR} statusCode:${error.httpStatusCode}`;
        }
    } else {
        parsedMessage = error.message;
    }
    return new Error(parsedMessage);
}

export const parseSharingErrorCodes = (error: any) => {
    let parsedMessage = null;
    if (error instanceof ApiError) {
        switch (error.httpStatusCode) {
            case HttpStatusCode.BadRequest:
                parsedMessage = CustomError.BAD_REQUEST;
                break;
            case HttpStatusCode.PaymentRequired:
                parsedMessage = CustomError.SUBSCRIPTION_NEEDED;
                break;
            case HttpStatusCode.NotFound:
                parsedMessage = CustomError.NOT_FOUND;
                break;
            case HttpStatusCode.Unauthorized:
            case HttpStatusCode.Gone:
                parsedMessage = CustomError.TOKEN_EXPIRED;
                break;
            case HttpStatusCode.TooManyRequests:
                parsedMessage = CustomError.TOO_MANY_REQUESTS;
                break;
            default:
                parsedMessage = `${CustomError.UNKNOWN_ERROR} statusCode:${error.httpStatusCode}`;
        }
    } else {
        parsedMessage = error.message;
    }
    return new Error(parsedMessage);
};
