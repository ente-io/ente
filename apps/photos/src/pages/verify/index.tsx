import VerifyPage from "@ente/accounts/pages/verify";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Verify() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <VerifyPage
            appContext={appContext}
            router={router}
            appName={APPS.PHOTOS}
        />
    );
}
