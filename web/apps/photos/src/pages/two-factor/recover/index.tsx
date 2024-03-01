import TwoFactorRecoverPage from "@ente/accounts/pages/two-factor/recover";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function TwoFactorRecover() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <TwoFactorRecoverPage
            appContext={appContext}
            router={router}
            appName={APPS.PHOTOS}
        />
    );
}
