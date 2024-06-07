import log from "@/next/log";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { accountsAppURL, getEndpoint } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

/**
 * Redirect user to accounts.ente.io (or its equivalent), to a page where they
 * can authenticate using their second factor, a passkey they've configured.
 *
 * On successful verification, accounts.ente.io will redirect back to our
 * `/passkeys/finish` page.
 *
 * @param passkeySessionID An identifier provided by museum for this passkey
 * verification session.
 */
export const redirectUserToPasskeyVerificationFlow = (
    passkeySessionID: string,
) => {
    const redirect = `${window.location.origin}/passkeys/finish`;
    const params = new URLSearchParams({ passkeySessionID, redirect });
    window.location.href = `${accountsAppURL()}/passkeys/verify?${params.toString()}`;
};

export const isPasskeyRecoveryEnabled = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${getEndpoint()}/users/two-factor/recovery-status`,
            {},
            {
                "X-Auth-Token": token,
            },
        );

        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }

        return resp.data["isPasskeyRecoveryEnabled"] as boolean;
    } catch (e) {
        log.error("failed to get passkey recovery status", e);
        throw e;
    }
};

export const configurePasskeyRecovery = async (
    secret: string,
    userSecretCipher: string,
    userSecretNonce: string,
) => {
    try {
        const token = getToken();

        const resp = await HTTPService.post(
            `${getEndpoint()}/users/two-factor/passkeys/configure-recovery`,
            {
                secret,
                userSecretCipher,
                userSecretNonce,
            },
            undefined,
            {
                "X-Auth-Token": token,
            },
        );

        if (typeof resp.data === "undefined") {
            throw Error(CustomError.REQUEST_FAILED);
        }
    } catch (e) {
        log.error("failed to configure passkey recovery", e);
        throw e;
    }
};
