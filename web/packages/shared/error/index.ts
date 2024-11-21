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
    ETAG_MISSING: "no header/etag present in response body",
    KEY_MISSING: "encrypted key missing from localStorage",
    FILE_TOO_LARGE: "file too large",
    SUBSCRIPTION_EXPIRED: "subscription expired",
    STORAGE_QUOTA_EXCEEDED: "storage quota exceeded",
    SESSION_EXPIRED: "session expired",
    TOKEN_EXPIRED: "token expired",
    TOKEN_MISSING: "token missing",
    TOO_MANY_REQUESTS: "too many requests",
    BAD_REQUEST: "bad request",
    SUBSCRIPTION_NEEDED: "subscription not present",
    NOT_FOUND: "not found ",
    WEAK_DEVICE: "password decryption failed on the device",
    INCORRECT_PASSWORD: "incorrect password",
    UPLOAD_CANCELLED: "upload cancelled",
    UPDATE_EXPORTED_RECORD_FAILED: "update file exported record failed",
    EXPORT_STOPPED: "export stopped",
    EXPORT_FOLDER_DOES_NOT_EXIST: "export folder does not exist",
    AUTH_KEY_NOT_FOUND: "auth key not found",
    TWO_FACTOR_ENABLED: "two factor enabled",
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
                parsedMessage = `Something went wrong (statusCode:${error.httpStatusCode})`;
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
                parsedMessage = `Something went wrong (statusCode:${error.httpStatusCode})`;
        }
    } else {
        parsedMessage = error.message;
    }
    return new Error(parsedMessage);
};
