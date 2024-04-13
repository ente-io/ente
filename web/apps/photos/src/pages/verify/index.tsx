import VerifyPage from "@ente/accounts/pages/verify";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Verify() {
    const appContext = useContext(AppContext);
    return <VerifyPage appContext={appContext} appName={APPS.PHOTOS} />;
}
