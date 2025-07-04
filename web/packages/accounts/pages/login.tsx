import { AccountsPageContents } from "ente-accounts/components/layouts/centered-paper";
import { LoginContents } from "ente-accounts/components/LoginContents";
import { savedPartialLocalUser } from "ente-accounts/services/accounts-db";
import { LoadingIndicator } from "ente-base/components/loaders";
import { customAPIHost } from "ente-base/origins";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";

/**
 * A page that allows the user to login into their existing Ente account.
 *
 * [Note: Login pages]
 *
 * There are multiple pages that comprise the login flow, with redirects amongst
 * themselves depending on various scenarios and partial login states.
 *
 * - "/signup" - A page that allows the user to signup for a new Ente account.
 *
 *   - Redirects to "/login" if the user chooses the "already have an account"
 *     option.
 *
 *   - Redirects to "/verify" if there is already an `email` present in the
 *     saved partial local user, or after obtaining the email.
 *
 * - "/login" - A page that allows the user to login into their existing Ente
 *   account.
 *
 *   - Redirects to "/signup" if the user chooses the "create new account"
 *     option.
 *
 *   - Redirects to "/verify" if there is already an `email` present in the
 *     saved partial local user, or after obtaining the email if the user's has
 *     enabled email verification for their account.
 *
 *   - Redirects to "/credentials" after obtaining the email if the user has not
 *     enabled email verification for their account.
 *
 * - "/verify" - A page that allows the user to verify their email.
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     local user.
 *
 *   - Redirects to "/credentials" if both saved key attributes and a `token`
 *     (or `encryptedToken`) in present in the saved partial local user, or if
 *     email verification is not needed, or when email verification completes
 *     and remote sent us key attributes (which will happen on login).
 *
 *   - Redirects to "/generate" once email verification is complete and the user
 *     does not have key attributes (which will happen for new signups).
 *
 *   - Redirects to "/two-factor/verify" when email verification completes and
 *     the user has setup a TOTP second factor that also needs to be verified.
 *
 *   - Redirects to the passkey app when email verification completes and the
 *     user has setup a passkey that also needs to be verified. Before
 *     redirecting, `inflightPasskeySessionID` in saved in session storage.
 *
 * - "/credentials" - A page that allows the user to enter their password to
 *   authenticate (initial login) or reauthenticate (new web app tab)
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     local user.
 *
 *   - Redirects to "/two-factor/verify" if saved key attributes are not present
 *     once password is verified and the user has setup a TOTP second factor
 *     that also needs to be verified.
 *
 *   - Redirects to the passkey app once password is verified if saved key
 *     attributes are not present if the user has setup a passkey that also
 *     needs to be verified. Before redirecting, `inflightPasskeySessionID` is
 *     saved in session storage.
 *
 *   - Redirects to the `appHomeRoute` otherwise (e.g. /gallery). **The flow is
 *     complete**.
 *
 * - "/generate" - A page that allows the user to generate key attributes if
 *   needed, and shows them their recovery key if they just signed up.
 *
 *   - Redirects to "/" if there is no `email` or `token` present in the saved
 *     partial user.
 *
 *   - Redirects to `appHomeRoute` after viewing the recovery key if they have a
 *     master key in session, or after setting the password and then viewing the
 *     recovery key (if they did not have a master key in session store).
 *
 *   - Redirects to "/credentials" if if they don't have a master key in session
 *     store but have saved original key attributes.
 *
 * - "/recover" - A page that allows the user to recover their master key using
 *   their recovery key.
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     local user.
 *
 *   - Redirects to "/verify" if there is no `encryptedToken` (or `token`)
 *     present in the saved partial local user.
 *
 *   - Redirects to "/generate" if there are no saved key attributes.
 *
 *   - Redirects to "/change-password" once the recovery key is verified.
 *
 * - "/change-password" - A page that allows the user to reset their password.
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     user, and after successfully changing the password.
 *
 * - "/two-factor/verify" - A page that allows the user to verify their TOTP
 *   based second factor.
 *
 *   - Redirects to "/" if there is no `email` or `twoFactorSessionID` in the
 *     saved partial local user.
 *
 *   - Redirects to "/credentials" if `isTwoFactorEnabled` is not `true` and
 *     either of `encryptedToken` or `token` is present in the saved partial
 *     local user.
 *
 * - "/passkeys/finish" - A page where the accounts app hands off control back
 *   to us (the calling app) once the passkey has been verified.
 *
 *   - Redirects to "/" if there is no matching `inflightPasskeySessionID` in
 *     session storage.
 *
 *   - Redirects to "/credentials" otherwise.
 *
 * - "/two-factor/recover" and "/passkeys/recover" - Pages that allow the user
 *   to reset or bypass their second factor if they possess their recovery key.
 *   Both pages work similarly, except for the second factor they act on.
 *
 *   - Redirect to "/" if there is no `email` or `twoFactorSessionID` /
 *     `passkeySessionID` in the saved partial local user.
 *
 *   - Redirect to "/generate" if there is an `encryptedToken` or `token` in the
 *     saved partial local user.
 *
 *   - Redirect to "/credentials" after recovery.
 *
 */
const Page: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>(undefined);

    const router = useRouter();

    useEffect(() => {
        void customAPIHost().then(setHost);
        if (savedPartialLocalUser()?.email) void router.replace("/verify");
        setLoading(false);
    }, [router]);

    const onSignUp = useCallback(() => void router.push("/signup"), [router]);

    return loading ? (
        <LoadingIndicator />
    ) : (
        <AccountsPageContents>
            <LoginContents {...{ host, onSignUp }} />
        </AccountsPageContents>
    );
};

export default Page;
