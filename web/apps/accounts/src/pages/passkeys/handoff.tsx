import log from "@/next/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

/**
 * Parse credentials passed as query parameters by one of our client apps, save
 * them to local storage, and then redirect to the passkeys listing.
 */
const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);

        const client = urlParams.get("client");
        if (client) {
            // TODO-PK: mobile is not passing it. is that expected?
            setData(LS_KEYS.CLIENT_PACKAGE, { name: client });
            HTTPService.setHeaders({
                "X-Client-Package": client,
            });
        }

        const token = urlParams.get("token");
        if (!token) {
            log.error("Missing accounts token");
            router.push("/login");
            return;
        }

        const user = getData(LS_KEYS.USER) || {};
        user.token = token;

        setData(LS_KEYS.USER, user);

        router.push("/passkeys");
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

export default Page;
