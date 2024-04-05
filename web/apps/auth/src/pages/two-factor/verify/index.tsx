import TwoFactorVerifyPage from "@ente/accounts/pages/two-factor/verify";
import { APPS } from "@ente/shared/apps/constants";
import { useContext } from "react";
import { AppContext } from "../../_app";

export default function TwoFactorVerify() {
    const appContext = useContext(AppContext);
    return <TwoFactorVerifyPage appContext={appContext} appName={APPS.AUTH} />;
}
