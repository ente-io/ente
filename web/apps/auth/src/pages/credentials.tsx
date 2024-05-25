import { ensure } from "@/utils/ensure";
import CredentialPage from "@ente/accounts/pages/credentials";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <CredentialPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
