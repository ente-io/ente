import GeneratePage from "@ente/accounts/pages/generate";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function Generate() {
    const appContext = useContext(AppContext);
    return <GeneratePage appContext={appContext} appName={APPS.PHOTOS} />;
}
