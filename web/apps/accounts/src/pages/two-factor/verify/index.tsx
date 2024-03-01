import TwoFactorVerifyPage from "@ente/accounts/pages/two-factor/verify";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function TwoFactorVerify() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <TwoFactorVerifyPage
            appContext={appContext}
            router={router}
            appName={APPS.ACCOUNTS}
        />
    );
}
