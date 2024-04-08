import LoginPage from "@ente/accounts/pages/login";
import { APPS } from "@ente/shared/apps/constants";
import { useContext } from "react";
import { AppContext } from "../_app";

export default function Login() {
    const appContext = useContext(AppContext);
    return <LoginPage appContext={appContext} appName={APPS.ACCOUNTS} />;
}
