import LoginPage from "@ente/accounts/pages/login";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { useContext } from "react";
import { AppContext } from "../_app";

export default function Login() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <LoginPage
            appContext={appContext}
            router={router}
            appName={APPS.ACCOUNTS}
        />
    );
}
