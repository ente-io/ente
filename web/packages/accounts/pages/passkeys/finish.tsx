import { PAGES } from "@ente/accounts/constants/pages";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();

    const init = async () => {
        // get response from query params
        const searchParams = new URLSearchParams(window.location.search);
        const response = searchParams.get("response");

        if (!response) return;

        // decode response
        const decodedResponse = JSON.parse(atob(response));

        // only one will be present
        // token only during fresh signup
        // encryptedToken othw
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
        router.push(redirectURL ?? PAGES.ROOT);
    };

    useEffect(() => {
        init();
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

export default Page;
