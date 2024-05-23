import CredentialPage from "@ente/accounts/pages/credentials";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Credential() {
    const appContext = useContext(AppContext);
    return <CredentialPage appContext={appContext} appName={APPS.AUTH} />;
}
