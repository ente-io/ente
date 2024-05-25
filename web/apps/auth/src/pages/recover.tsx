import { ensure } from "@/utils/ensure";
import RecoverPage from "@ente/accounts/pages/recover";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <RecoverPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
