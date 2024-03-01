import GeneratePage from "@ente/accounts/pages/generate";
import { APPS } from "@ente/shared/apps/constants";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Generate() {
    const appContext = useContext(AppContext);
    const router = useRouter();
    return (
        <GeneratePage
            appContext={appContext}
            router={router}
            appName={APPS.ACCOUNTS}
        />
    );
}
