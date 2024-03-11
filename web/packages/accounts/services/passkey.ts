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

export const configurePasskeyRecovery = async (
    secret: string,
    userEncryptedSecret: string,
    userSecretNonce: string,
) => {
    try {
        const token = getToken();

        const resp = await HTTPService.post("/users/two-factor/passkeys/configure-recovery", {
            secret,
            userEncryptedSecret,
            userSecretNonce,
        }, {
            "X-Auth-Token": token,
        });

        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
    } catch (e) {
        logError(e, "failed to configure passkey recovery");
        throw e
    }
}