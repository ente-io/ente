import log from "@/next/log";
import type { AppName } from "@/next/types/app";
import { clientPackageName } from "@/next/types/app";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import {
    encryptToB64,
    generateEncryptionKey,
} from "@ente/shared/crypto/internal/libsodium";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { accountsAppURL, apiOrigin } from "@ente/shared/network/api";
import { getToken } from "@ente/shared/storage/localStorage/helpers";

/**
 * Redirect user to Ente accounts app to authenticate using their second factor,
 * a passkey they've configured.
 *
 * On successful verification, the accounts app will redirect back to our
 * `/passkeys/finish` page.
 *
 * @param appName The {@link AppName} of the app which is calling this function.
 *
 * @param passkeySessionID An identifier provided by museum for this passkey
 * verification session.
 */
export const redirectUserToPasskeyVerificationFlow = (
    appName: AppName,
    passkeySessionID: string,
) => {
    const clientPackage = clientPackageName[appName];
    const redirect = `${window.location.origin}/passkeys/finish`;
    const params = new URLSearchParams({
        clientPackage,
        passkeySessionID,
        redirect,
    });
    window.location.href = `${accountsAppURL()}/passkeys/verify?${params.toString()}`;
};

/**
 * Open a new window showing a page on the Ente accounts app where the user can
 * see and their manage their passkeys.
 *
 * @param appName The {@link AppName} of the app which is calling this function.
 */
export const openAccountsManagePasskeysPage = async (appName: AppName) => {
    // check if the user has passkey recovery enabled
    const recoveryEnabled = await isPasskeyRecoveryEnabled();
    if (!recoveryEnabled) {
        // let's create the necessary recovery information
        const recoveryKey = await getRecoveryKey();

        const resetSecret = await generateEncryptionKey();

        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const encryptionResult = await encryptToB64(
            resetSecret,
            await cryptoWorker.fromHex(recoveryKey),
        );

        await configurePasskeyRecovery(
            resetSecret,
            encryptionResult.encryptedData,
            encryptionResult.nonce,
        );
    }

    const token = await getAccountsToken();
    const client = clientPackageName[appName];
    const params = new URLSearchParams({ token, client });

    window.open(`${accountsAppURL()}/passkeys/handoff?${params.toString()}`);
};

export const isPasskeyRecoveryEnabled = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            `${apiOrigin()}/users/two-factor/recovery-status`,
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

const configurePasskeyRecovery = async (
    secret: string,
    userSecretCipher: string,
    userSecretNonce: string,
) => {
    try {
        const token = getToken();

        const resp = await HTTPService.post(
            `${apiOrigin()}/users/two-factor/passkeys/configure-recovery`,
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

/**
 * Fetch an Ente Accounts specific JWT token.
 *
 * This token can be used to authenticate with the Ente accounts app.
 */
const getAccountsToken = async () => {
    const token = getToken();

    const resp = await HTTPService.get(
        `${apiOrigin()}/users/accounts-token`,
        undefined,
        {
            "X-Auth-Token": token,
        },
    );
    return resp.data["accountsToken"];
};
