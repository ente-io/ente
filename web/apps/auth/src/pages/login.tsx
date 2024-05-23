import LoginPage from "@ente/accounts/pages/login";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Login() {
    const appContext = useContext(AppContext);
    return <LoginPage appContext={appContext} appName={APPS.AUTH} />;
}
