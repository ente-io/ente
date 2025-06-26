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
    TOKEN_EXPIRED: "token expired",
    TOO_MANY_REQUESTS: "too many requests",
    BAD_REQUEST: "bad request",
    SUBSCRIPTION_NEEDED: "subscription not present",
    NOT_FOUND: "not found ",
    UPDATE_EXPORTED_RECORD_FAILED: "update file exported record failed",
    EXPORT_STOPPED: "export stopped",
    EXPORT_FOLDER_DOES_NOT_EXIST: "export folder does not exist",
    TWO_FACTOR_ENABLED: "two factor enabled",
};

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
