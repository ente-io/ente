import CredentialPage from "@ente/accounts/pages/credentials";
import { APPS } from "@ente/shared/apps/constants";
import { useContext } from "react";
import { AppContext } from "../_app";

export default function Credential() {
    const appContext = useContext(AppContext);
    return <CredentialPage appContext={appContext} appName={APPS.ACCOUNTS} />;
}
