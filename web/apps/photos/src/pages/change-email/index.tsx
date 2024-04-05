import ChangeEmailPage from "@ente/accounts/pages/change-email";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function ChangeEmail() {
    const appContext = useContext(AppContext);
    return <ChangeEmailPage appContext={appContext} appName={APPS.PHOTOS} />;
}
