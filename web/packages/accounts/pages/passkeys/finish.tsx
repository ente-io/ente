import log from "@/next/log";
import { nullToUndefined } from "@/utils/transform";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { fromB64URLSafeNoPaddingString } from "@ente/shared/crypto/internal/libsodium";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect } from "react";
import { PAGES } from "../../constants/pages";
import type { PageProps } from "../../types/page";

/**
 * [Note: Finish passkey flow in the requesting app]
 *
 * The passkey finish step needs to happen in the context of the client which
 * invoked the passkey flow since it needs to save the obtained credentials
 * in local storage (which is tied to the current origin).
 */
const Page: React.FC<PageProps> = () => {
    const router = useRouter();

    useEffect(() => {
        // Extract response from query params
        const searchParams = new URLSearchParams(window.location.search);
        const passkeySessionID = searchParams.get("passkeySessionID");
        const response = searchParams.get("response");
        if (!passkeySessionID || !response) return;

        saveCredentialsAndNavigateTo(passkeySessionID, response).then(
            (slug: string) => {
                router.push(slug);
            },
        );
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
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
const saveCredentialsAndNavigateTo = async (
    passkeySessionID: string,
    response: string,
) => {
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

    sessionStorage.removeItem("inflightPasskeySessionID");

    // Decode response string (inverse of the steps we perform in
    // `passkeyAuthenticationSuccessRedirectURL`).
    const decodedResponse = JSON.parse(
        await fromB64URLSafeNoPaddingString(response),
    );

    // Only one of `encryptedToken` or `token` will be present depending on the
    // account's lifetime:
    //
    // - The plaintext "token" will be passed during fresh signups, where we
    //   don't yet have keys to encrypt it, the account itself is being created
    //   as we go through this flow.
    //   TODO(MR): Conceptually this cannot happen. During a _real_ fresh signup
    //   we'll never enter the passkey verification flow. Remove this code after
    //   making sure that it doesn't get triggered in cases where an existing
    //   user goes through the new user flow.
    //
    // - The encrypted `encryptedToken` will be present otherwise (i.e. if the
    //   user is signing into an existing account).
    const { keyAttributes, encryptedToken, token, id } = decodedResponse;

    setData(LS_KEYS.USER, {
        ...getData(LS_KEYS.USER),
        token,
        encryptedToken,
        id,
    });
    setData(LS_KEYS.KEY_ATTRIBUTES, keyAttributes);

    const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
    InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
    return redirectURL ?? PAGES.CREDENTIALS;
};
