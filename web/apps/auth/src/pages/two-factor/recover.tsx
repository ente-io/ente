import TwoFactorRecoverPage from "@ente/accounts/pages/two-factor/recover";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function TwoFactorRecover() {
    const appContext = useContext(AppContext);
    return <TwoFactorRecoverPage appContext={appContext} appName={APPS.AUTH} />;
}
