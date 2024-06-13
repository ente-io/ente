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
 * Construct a redirect URL to take the user to Ente accounts app to
 * authenticate using their second factor, a passkey they've configured.
 *
 * On successful verification, the accounts app will redirect back to our
 * `/passkeys/finish` page.
 *
 * @param appName The {@link AppName} of the app which is calling this function.
 *
 * @param passkeySessionID An identifier provided by museum for this passkey
 * verification session.
 */
export const passkeyVerificationRedirectURL = (
    appName: AppName,
    passkeySessionID: string,
) => {
    const clientPackage = clientPackageName(appName);
    // Using `window.location.origin` will work both when we're running in a web
    // browser, and in our desktop app. See: [Note: Using deeplinks to navigate
    // in desktop app]
    const redirect = `${window.location.origin}/passkeys/finish`;
    // See: [Note: Conditional passkey recover option on accounts]
    const recoverOption: Record<string, string> = globalThis.electron
        ? {}
        : { recover: `${window.location.origin}/passkeys/recover` };
    const params = new URLSearchParams({
        clientPackage,
        passkeySessionID,
        redirect,
        ...recoverOption,
    });
    return `${accountsAppURL()}/passkeys/verify?${params.toString()}`;
};

/**
 * Open or redirect to a passkey verification URL previously constructed using
 * {@link passkeyVerificationRedirectURL}.
 *
 * @param passkeySessionID The passkeySessionID for which we are redirecting.
 * This is saved to session storage to allow us to ignore subsequent redirects
 * to the passkey flow finish page except the ones for this specific session.
 *
 * @param url The URL to redirect to or open in the system browser.
 *
 * [Note: Passkey verification in the desktop app]
 *
 * Our desktop app bundles the web app and serves it over a custom protocol.
 * Passkeys are tied to origins, and will not work with this custom protocol
 * even if we move the passkey creation and authentication inline to within the
 * Photos web app.
 *
 * Thus, passkey creation and authentication in the desktop app works the same
 * way it works in the mobile app - the system browser is invoked to open
 * accounts.ente.io.
 *
 * -   For passkey creation, this is a one-way open. Passkeys get created at
 *     accounts.ente.io, and that's it.
 *
 * -   For passkey verification, the flow is two-way. We register a custom
 *     protocol and provide that as a return path redirect. Passkey
 *     authentication happens at accounts.ente.io, and on success there is
 *     redirected back to the desktop app.
 */
export const openPasskeyVerificationURL = (
    passkeySessionID: string,
    url: string,
) => {
    sessionStorage.setItem("inflightPasskeySessionID", passkeySessionID);

    if (globalThis.electron) window.open(url);
    else window.location.href = url;
};

/**
 * Open a new window showing a page on the Ente accounts app where the user can
 * see and their manage their passkeys.
 *
 * @param appName The {@link AppName} of the app which is calling this function.
 */
export const openAccountsManagePasskeysPage = async () => {
    // Check if the user has passkey recovery enabled
    const recoveryEnabled = await isPasskeyRecoveryEnabled();
    if (!recoveryEnabled) {
        // If not, enable it for them by creating the necessary recovery
        // information to prevent them from getting locked out.
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

    // Redirect to the Ente Accounts app where they can view and add and manage
    // their passkeys.
    const token = await getAccountsToken();
    const params = new URLSearchParams({ token });

    window.open(`${accountsAppURL()}/passkeys?${params.toString()}`);
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
