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

        const clientPackage = urlParams.get("client");
        if (clientPackage) {
            // TODO-PK: mobile is not passing it. is that expected?
            localStorage.setItem("clientPackage", clientPackage);
            HTTPService.setHeaders({
                "X-Client-Package": clientPackage,
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
