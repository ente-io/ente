import { clientPackageHeaderIfPresent } from "@/next/http";
import log from "@/next/log";
import type { AppName } from "@/next/types/app";
import { clientPackageName } from "@/next/types/app";
import { TwoFactorAuthorizationResponse } from "@/next/types/credentials";
import { ensure } from "@/utils/ensure";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import {
    encryptToB64,
    generateEncryptionKey,
} from "@ente/shared/crypto/internal/libsodium";
import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { accountsAppURL, apiOrigin } from "@ente/shared/network/api";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
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

interface OpenPasskeyVerificationURLOptions {
    /**
     * The passkeySessionID for which we are redirecting.
     *
     * This is compared to the saved session id in the browser's session storage
     * to allow us to ignore redirects to the passkey flow finish page except
     * the ones for this specific session we're awaiting.
     */
    passkeySessionID: string;
    /** The URL to redirect to or open in the system browser. */
    url: string;
}

/**
 * Open or redirect to a passkey verification URL previously constructed using
 * {@link passkeyVerificationRedirectURL}.
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
export const openPasskeyVerificationURL = ({
    passkeySessionID,
    url,
}: OpenPasskeyVerificationURLOptions) => {
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

/**
 * The passkey session whose status we are trying to check has already expired.
 * The user should attempt to login again.
 */
export const passkeySessionExpiredErrorMessage = "Passkey session has expired";

/**
 * Check if the user has already authenticated using their passkey for the given
 * session.
 *
 * This is useful in case the automatic redirect back from accounts.ente.io to
 * the desktop app does not work for some reason. In such cases, the user can
 * press the "Check status" button: we'll make an API call to see if the
 * authentication has already completed, and if so, get the same "response"
 * object we'd have gotten as a query parameter in a redirect in
 * {@link saveCredentialsAndNavigateTo} on the "/passkeys/finish" page.
 *
 * @param sessionID The passkey session whose session we wish to check the
 * status of.
 *
 * @returns A {@link TwoFactorAuthorizationResponse} if the passkey
 * authentication has completed, and `undefined` otherwise.
 *
 * @throws In addition to arbitrary errors, it throws errors with the message
 * {@link passkeySessionExpiredErrorMessage}.
 */
export const checkPasskeyVerificationStatus = async (
    sessionID: string,
): Promise<TwoFactorAuthorizationResponse | undefined> => {
    const url = `${apiOrigin()}/users/two-factor/passkeys/get-token`;
    const params = new URLSearchParams({ sessionID });
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: clientPackageHeaderIfPresent(),
    });
    if (!res.ok) {
        if (res.status == 404 || res.status == 410)
            throw new Error(passkeySessionExpiredErrorMessage);
        if (res.status == 400) return undefined; /* verification pending */
        throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    }
    return TwoFactorAuthorizationResponse.parse(await res.json());
};

/**
 * Extract credentials from a successful passkey verification response and save
 * them to local storage for use by subsequent steps (or normal functioning) of
 * the app.
 *
 * @param response The result of a successful
 * {@link checkPasskeyVerificationStatus}.
 *
 * @returns the slug that we should navigate to now.
 */
export const saveCredentialsAndNavigateTo = (
    response: TwoFactorAuthorizationResponse,
) => {
    // This method somewhat duplicates `saveCredentialsAndNavigateTo` in the
    // /passkeys/finish page.
    const { id, encryptedToken, keyAttributes } = response;

    setData(LS_KEYS.USER, {
        ...getData(LS_KEYS.USER),
        encryptedToken,
        id,
    });
    setData(LS_KEYS.KEY_ATTRIBUTES, ensure(keyAttributes));

    // TODO(MR): Remove the cast.
    const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL) as
        | string
        | undefined;
    InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
    return redirectURL ?? "/credentials";
};
