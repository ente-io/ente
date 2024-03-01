import { WorkerSafeElectronService } from "@ente/shared/electron/service";
import {
    getLocalSentryUserID,
    setLocalSentryUserID,
} from "@ente/shared/storage/localStorage/helpers";
import { HttpStatusCode } from "axios";
import isElectron from "is-electron";
import { ApiError } from "../error";

export async function getSentryUserID() {
    if (isElectron()) {
        return await WorkerSafeElectronService.getSentryUserID();
    } else {
        let anonymizeUserID = getLocalSentryUserID();
        if (!anonymizeUserID) {
            anonymizeUserID = makeID(6);
            setLocalSentryUserID(anonymizeUserID);
        }
        return anonymizeUserID;
    }
}

function makeID(length) {
    let result = "";
    const characters =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength),
        );
    }
    return result;
}

export function isErrorUnnecessaryForSentry(error: any) {
    if (error?.message?.includes("Network Error")) {
        return true;
    } else if (
        error instanceof ApiError &&
        error.httpStatusCode === HttpStatusCode.Unauthorized
    ) {
        return true;
    }
    return false;
}
