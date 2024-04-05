import TwoFactorSetupPage from "@ente/accounts/pages/two-factor/setup";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function TwoFactorSetup() {
    const appContext = useContext(AppContext);
    return <TwoFactorSetupPage appContext={appContext} appName={APPS.PHOTOS} />;
}
