import { clientPackageName, isDesktop } from "@/base/app";
import { sharedCryptoWorker } from "@/base/crypto";
import { encryptToB64, generateEncryptionKey } from "@/base/crypto/libsodium";
import { HTTPError, publicRequestHeaders } from "@/base/http";
import log from "@/base/log";
import { accountsAppOrigin, apiURL } from "@/base/origins";
import { TwoFactorAuthorizationResponse } from "@/base/types/credentials";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import HTTPService from "@ente/shared/network/HTTPService";
import {
    getData,
    LS_KEYS,
    setData,
    setLSUser,
} from "@ente/shared/storage/localStorage";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { unstashRedirect } from "./redirect";

/**
 * Construct a redirect URL to take the user to Ente accounts app to
 * authenticate using their second factor, a passkey they've configured.
 *
 * On successful verification, the accounts app will redirect back to our
 * `/passkeys/finish` page.
 *
 * @param passkeySessionID An identifier provided by museum for this passkey
 * verification session.
 */
export const passkeyVerificationRedirectURL = (passkeySessionID: string) => {
    const clientPackage = clientPackageName;
    // Using `window.location.origin` will work both when we're running in a web
    // browser, and in our desktop app. See: [Note: Using deeplinks to navigate
    // in desktop app]
    const redirect = `${window.location.origin}/passkeys/finish`;
    // See: [Note: Conditional passkey recover option on accounts]
    const recoverOption: Record<string, string> = isDesktop
        ? {}
        : { recover: `${window.location.origin}/passkeys/recover` };
    const params = new URLSearchParams({
        clientPackage,
        passkeySessionID,
        redirect,
        ...recoverOption,
    });
    return `${accountsAppOrigin()}/passkeys/verify?${params.toString()}`;
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
 */
export const openAccountsManagePasskeysPage = async () => {
    // Check if the user has passkey recovery enabled
    const recoveryEnabled = await isPasskeyRecoveryEnabled();
    if (!recoveryEnabled) {
        // If not, enable it for them by creating the necessary recovery
        // information to prevent them from getting locked out.
        const recoveryKey = await getRecoveryKey();

        const resetSecret = await generateEncryptionKey();

        const cryptoWorker = await sharedCryptoWorker();
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

    window.open(`${accountsAppOrigin()}/passkeys?${params.toString()}`);
};

export const isPasskeyRecoveryEnabled = async () => {
    try {
        const token = getToken();

        const resp = await HTTPService.get(
            await apiURL("/users/two-factor/recovery-status"),
            {},
            {
                "X-Auth-Token": token,
            },
        );

        if (typeof resp.data === "undefined") {
            throw Error("request failed");
        }

        return resp.data.isPasskeyRecoveryEnabled as boolean;
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
            await apiURL("/users/two-factor/passkeys/configure-recovery"),
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
            throw Error("request failed");
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
        await apiURL("/users/accounts-token"),
        undefined,
        {
            "X-Auth-Token": token,
        },
    );
    return resp.data.accountsToken;
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
    const url = await apiURL("/users/two-factor/passkeys/get-token");
    const params = new URLSearchParams({ sessionID });
    const res = await fetch(`${url}?${params.toString()}`, {
        headers: publicRequestHeaders(),
    });
    if (!res.ok) {
        if (res.status == 404 || res.status == 410)
            throw new Error(passkeySessionExpiredErrorMessage);
        if (res.status == 400) return undefined; /* verification pending */
        throw new HTTPError(res);
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
export const saveCredentialsAndNavigateTo = async (
    response: TwoFactorAuthorizationResponse,
) => {
    // This method somewhat duplicates `saveCredentialsAndNavigateTo` in the
    // /passkeys/finish page.
    const { id, encryptedToken, keyAttributes } = response;

    await setLSUser({
        ...getData(LS_KEYS.USER),
        encryptedToken,
        id,
    });
    setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes!);

    return unstashRedirect() ?? "/credentials";
};
