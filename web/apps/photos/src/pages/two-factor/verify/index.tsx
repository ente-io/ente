import TwoFactorVerifyPage from "@ente/accounts/pages/two-factor/verify";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function TwoFactorVerify() {
    const appContext = useContext(AppContext);
    return (
        <TwoFactorVerifyPage appContext={appContext} appName={APPS.PHOTOS} />
    );
}
