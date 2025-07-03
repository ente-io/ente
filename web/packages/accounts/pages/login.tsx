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
 *   - Redirects to "/credentials" if email verification is not needed, and also
 *     when email verification completes.
 *
 *   - Redirects to "/two-factor/verify" once email verification is complete if
 *     the user has setup an additional TOTP second factor that also needs to be
 *     verified.
 *
 *   - Redirects to the passkey app once email verification is complete if the
 *     user has setup an additional passkey that also needs to be verified.
 *
 * - "/credentials" - A page that allows the user to enter their password to
 *   authenticate (initial login) or reauthenticate (new web app tab)
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     local user.
 *
 * - "/generate" - A page that allows the user to generate key attributes if
 *   needed, and shows them their recovery key.
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     local user, or after viewing the recovery key, or after the user sets
 *     their password (if they did no have key attributes).
 *
 *   - Redirects to "/credentials" if they already have the original key
 *     attributes.
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
 *  - "/change-password" - A page that allows the user to reset their password.
 *
 *   - Redirects to "/" if there is no `email` present in the saved partial
 *     user, and after successfully changing the password.
 *
 */
const Page: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [host, setHost] = useState<string | undefined>(undefined);

    const router = useRouter();

    useEffect(() => {
        void customAPIHost().then(setHost);
        if (savedPartialLocalUser()?.email) void router.push("/verify");
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
