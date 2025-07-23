import {
    saveKeyAttributes,
    updateSavedLocalUser,
} from "ente-accounts/services/accounts-db";
import {
    resetSavedLocalUserTokens,
    TwoFactorAuthorizationResponse,
} from "ente-accounts/services/user";
import { clientPackageName, isDesktop } from "ente-base/app";
import { encryptBox, generateKey } from "ente-base/crypto";
import {
    authenticatedRequestHeaders,
    ensureOk,
    HTTPError,
    publicRequestHeaders,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { z } from "zod/v4";
import { getUserRecoveryKey } from "./recovery-key";
import { unstashRedirect } from "./redirect";

/**
 * Construct a redirect URL to take the user to Ente accounts app to
 * authenticate using their second factor, a passkey they've configured.
 *
 * On successful verification, the accounts app will redirect back to our
 * `/passkeys/finish` page.
 *
 * @param accountsURL The URL for the accounts app (provided to us by remote in
 * the email or SRP verification response).
 *
 * @param passkeySessionID An identifier provided by museum for this passkey
 * verification session.
 */
export const passkeyVerificationRedirectURL = (
    accountsURL: string,
    passkeySessionID: string,
) => {
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
    return `${accountsURL}/passkeys/verify?${params.toString()}`;
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
 * - For passkey creation, this is a one-way open. Passkeys get created at
 *   accounts.ente.io, and that's it.
 *
 * - For passkey verification, the flow is two-way. We register a custom
 *   protocol and provide that as a return path redirect. Passkey authentication
 *   happens at accounts.ente.io, and on success there is redirected back to the
 *   desktop app.
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
    // Check if the user has passkey recovery enabled.
    const { isPasskeyRecoveryEnabled } = await getTwoFactorRecoveryStatus();
    if (!isPasskeyRecoveryEnabled) {
        // If not, enable it for them by creating the necessary recovery
        // information to prevent them from getting locked out.
        const resetSecret = await generateKey();
        const { encryptedData, nonce } = await encryptBox(
            resetSecret,
            await getUserRecoveryKey(),
        );
        await configurePasskeyRecovery(resetSecret, encryptedData, nonce);
    }

    // Redirect to the Ente Accounts app where they can view and add and manage
    // their passkeys.
    const { accountsToken: token, accountsUrl: accountsURL } =
        await getAccountsTokenAndURL();
    const params = new URLSearchParams({ token });

    window.open(`${accountsURL}/passkeys?${params.toString()}`);
};

const TwoFactorRecoveryStatus = z.object({
    /**
     * `true` if the passkey recovery setup has been completed.
     */
    isPasskeyRecoveryEnabled: z.boolean(),
});

/**
 * Obtain the second factor recovery status from remote.
 */
export const getTwoFactorRecoveryStatus = async () => {
    const res = await fetch(await apiURL("/users/two-factor/recovery-status"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return TwoFactorRecoveryStatus.parse(await res.json());
};

/**
 * Allow the user to bypass their passkeys by saving the provided recovery
 * credentials on remote.
 */
const configurePasskeyRecovery = async (
    secret: string,
    userSecretCipher: string,
    userSecretNonce: string,
) =>
    ensureOk(
        await fetch(
            await apiURL("/users/two-factor/passkeys/configure-recovery"),
            {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    secret,
                    userSecretCipher,
                    userSecretNonce,
                }),
            },
        ),
    );

/**
 * Fetch an Ente Accounts specific JWT token.
 *
 * This token can be used to authenticate with the Ente accounts app running at
 * accountsURL (the result contains both pieces of information).
 */
const getAccountsTokenAndURL = async () => {
    const res = await fetch(await apiURL("/users/accounts-token"), {
        headers: await authenticatedRequestHeaders(),
    });
    ensureOk(res);
    return z
        .object({
            // The origin that serves the accounts app.
            accountsUrl: z.string(),
            // A token that can be used to authenticate with the accounts app.
            accountsToken: z.string(),
        })
        .parse(await res.json());
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
    const res = await fetch(
        await apiURL("/users/two-factor/passkeys/get-token", { sessionID }),
        { headers: publicRequestHeaders() },
    );
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
    // [Note: Ending the passkey flow]
    //
    // The implementation of this function is similar to that of the
    // `saveQueryCredentialsAndNavigateTo` on the "/passkeys/finish" page.
    //
    // This one, `saveCredentialsAndNavigateTo`, is used when the user presses
    // the check verification status button on the page that triggered the
    // passkey flow (when they're using the desktop app).
    //
    // The other one, `saveQueryCredentialsAndNavigateTo`, is used when the user
    // goes through the passkey flow in the browser itself (when they are using
    // the web app).

    clearInflightPasskeySessionID();

    const { id, encryptedToken, keyAttributes } = response;

    await resetSavedLocalUserTokens(id, encryptedToken);
    updateSavedLocalUser({ passkeySessionID: undefined });
    saveKeyAttributes(keyAttributes);

    return unstashRedirect() ?? "/credentials";
};

/**
 * Remove the inflight passkey session ID, if any, present in session storage.
 *
 * This should be called whenever we get back control from the passkey app to
 * clean up after ourselves.
 */
export const clearInflightPasskeySessionID = () => {
    sessionStorage.removeItem("inflightPasskeySessionID");
};
