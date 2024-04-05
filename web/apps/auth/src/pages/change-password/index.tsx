import ChangePasswordPage from "@ente/accounts/pages/change-password";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function ChangePassword() {
    const appContext = useContext(AppContext);
    return <ChangePasswordPage appContext={appContext} appName={APPS.AUTH} />;
}
