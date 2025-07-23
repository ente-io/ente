import {
    saveKeyAttributes,
    updateSavedLocalUser,
} from "ente-accounts/services/accounts-db";
import { clearInflightPasskeySessionID } from "ente-accounts/services/passkey";
import { unstashRedirect } from "ente-accounts/services/redirect";
import {
    resetSavedLocalUserTokens,
    TwoFactorAuthorizationResponse,
} from "ente-accounts/services/user";
import { LoadingIndicator } from "ente-base/components/loaders";
import { fromB64URLSafeNoPadding } from "ente-base/crypto";
import log from "ente-base/log";
import { nullToUndefined } from "ente-utils/transform";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

/**
 * The page where the accounts app hands back control to us once the passkey has
 * been verified.
 *
 * See: [Note: Login pages]
 *
 * [Note: Finish passkey flow in the requesting app]
 *
 * The passkey finish step needs to happen in the context of the client which
 * invoked the passkey flow since it needs to save the obtained credentials
 * in local storage (which is tied to the current origin).
 */
const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        // Extract response from query params.
        const searchParams = new URLSearchParams(window.location.search);
        const passkeySessionID = searchParams.get("passkeySessionID");
        const response = searchParams.get("response");
        if (!passkeySessionID || !response) return;

        void saveQueryCredentialsAndNavigateTo(passkeySessionID, response).then(
            (slug) => router.replace(slug),
        );
    }, [router]);

    return <LoadingIndicator />;
};

export default Page;

/**
 * Extract credentials from a successful passkey flow "response" query parameter
 * and save them to local storage for use by subsequent steps (or normal
 * functioning) of the app.
 *
 * @param passkeySessionID The string that is passed as the "passkeySessionID"
 * query parameter to us.
 *
 * @param response The string that is passed as the "response" query parameter to
 * us (we're the final "finish" page in the passkey flow).
 *
 * @returns the slug that we should navigate to now.
 */
const saveQueryCredentialsAndNavigateTo = async (
    passkeySessionID: string,
    response: string,
) => {
    // This function's implementation is on the same lines as that of the
    // `saveCredentialsAndNavigateTo` function in passkey utilities.
    //
    // See: [Note: Ending the passkey flow]

    const inflightPasskeySessionID = nullToUndefined(
        sessionStorage.getItem("inflightPasskeySessionID"),
    );

    if (
        !inflightPasskeySessionID ||
        passkeySessionID != inflightPasskeySessionID
    ) {
        // This is not the princess we were looking for. However, we have
        // already entered this castle. Redirect back to home without changing
        // any state, hopefully this will get the user back to where they were.
        log.info(
            `Ignoring redirect for unexpected passkeySessionID ${passkeySessionID}`,
        );
        return "/";
    }

    clearInflightPasskeySessionID();

    // Decode response string (inverse of the steps we perform in
    // `passkeyAuthenticationSuccessRedirectURL`).
    const decodedResponse = TwoFactorAuthorizationResponse.parse(
        JSON.parse(
            new TextDecoder().decode(await fromB64URLSafeNoPadding(response)),
        ),
    );

    const { id, keyAttributes, encryptedToken } = decodedResponse;

    await resetSavedLocalUserTokens(id, encryptedToken);
    updateSavedLocalUser({ passkeySessionID: undefined });
    saveKeyAttributes(keyAttributes);

    return unstashRedirect() ?? "/credentials";
};
