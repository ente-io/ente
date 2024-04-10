import { APPS } from "@ente/shared/apps/constants";
import NotFoundPage from "@ente/shared/next/pages/404";
import { AppContext } from "pages/_app";
import { useContext } from "react";

export default function NotFound() {
    const appContext = useContext(AppContext);
    return <NotFoundPage appContext={appContext} appName={APPS.AUTH} />;
}
