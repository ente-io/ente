import CredentialPage from "@ente/accounts/pages/credentials";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Credential() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <CredentialPage
            appContext={appContext}
            router={router}
            appName={APPS.PHOTOS}
        />
    );
}
