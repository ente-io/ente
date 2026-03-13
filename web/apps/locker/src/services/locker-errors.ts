import { HTTPError } from "ente-base/http";
import { t } from "i18next";

type LockerMutationAction = "createItem" | "uploadFile";

const museumErrorCode = async (error: HTTPError) => {
    try {
        const payload = (await error.res.clone().json()) as { code?: unknown };
        return typeof payload.code === "string" ? payload.code : undefined;
    } catch {
        return undefined;
    }
};

export const formatLockerMutationError = async (
    error: unknown,
    action: LockerMutationAction,
) => {
    if (error instanceof HTTPError) {
        if (error.res.status === 402) {
            return t("uploadSubscriptionExpiredErrorBody");
        }
        if (error.res.status === 426) {
            return t("uploadStorageLimitErrorBody");
        }
        if (error.res.status === 413) {
            return t("uploadFileTooLargeErrorBody");
        }

        const code = await museumErrorCode(error);
        if (error.res.status === 403 && code === "FILE_LIMIT_REACHED") {
            return t(
                action === "uploadFile"
                    ? "uploadFileCountLimitErrorBody"
                    : "uploadFileCountLimitErrorToast",
            );
        }
    }

    if (error instanceof Error) {
        return error.message;
    }

    return t(action === "uploadFile" ? "uploadError" : "failedToSaveRecord");
};
