import { PAGES } from "@ente/accounts/constants/pages";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

/**
 * [Note: Finish passkey flow in the requesting app]
 *
 * The passkey finish step needs to happen in the context of the client which
 * invoked the passkey flow since it needs to save the obtained credentials
 * in local storage (which is tied to the current origin).
 */
const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        // Extract response from query params
        const searchParams = new URLSearchParams(window.location.search);
        const response = searchParams.get("response");
        if (!response) return;

        saveCredentials(response);

        const redirectURL = InMemoryStore.get(MS_KEYS.REDIRECT_URL);
        InMemoryStore.delete(MS_KEYS.REDIRECT_URL);
        router.push(redirectURL ?? PAGES.ROOT);
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
 * @param response The string that is passed as the response query parameter to
 * us (we're the final "finish" page in the passkey flow).
 */
const saveCredentials = (response: string) => {
    // Decode response string.
    const decodedResponse = JSON.parse(atob(response));

    // Only one of `encryptedToken` or `token` will be present depending on the
    // account's lifetime:
    //
    // - The plaintext "token" will be passed during fresh signups, where we
    //   don't yet have keys to encrypt it, the account itself is being created
    //   as we go through this flow.
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
};
