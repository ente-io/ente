import HTTPService from "@ente/shared/network/HTTPService";
import { getToken } from "@ente/shared/storage/localStorage/helpers"
import { logError } from "@ente/shared/sentry";
import { CustomError } from "@ente/shared/error";

export const isPasskeyRecoveryEnabled = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get("/users/two-factor/recovery-status", {}, {
            "X-Auth-Token": token,
        });

        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }

        return resp.isPasskeyRecoveryEnabled as boolean;

    } catch (e) {
        logError(e, "failed to get passkey recovery status");
        throw e
    }
}