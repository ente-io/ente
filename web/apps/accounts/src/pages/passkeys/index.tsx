import log from "@/next/log";
import { VerticallyCentered } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import HTTPService from "@ente/shared/network/HTTPService";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { useRouter } from "next/router";
import React, { useEffect } from "react";

const Page: React.FC = () => {
    const router = useRouter();

    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);

        const pkg = urlParams.get("package");
        if (pkg) {
            // TODO-PK: mobile is not passing it. is that expected?
            setData(LS_KEYS.CLIENT_PACKAGE, { name: pkg });
            HTTPService.setHeaders({
                "X-Client-Package": pkg,
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

        router.push("/passkeys/setup");
    }, []);

    return (
        <VerticallyCentered>
            <EnteSpinner />
        </VerticallyCentered>
    );
};

export default Page;
