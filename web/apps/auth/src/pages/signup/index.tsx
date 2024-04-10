import SignupPage from "@ente/accounts/pages/signup";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Sigup() {
    const appContext = useContext(AppContext);
    return <SignupPage appContext={appContext} appName={APPS.AUTH} />;
}
