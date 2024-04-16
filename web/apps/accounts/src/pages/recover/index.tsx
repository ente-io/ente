import RecoverPage from "@ente/accounts/pages/recover";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Recover() {
    const appContext = useContext(AppContext);
    return <RecoverPage appContext={appContext} appName={APPS.ACCOUNTS} />;
}
