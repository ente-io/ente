import { ensure } from "@/utils/ensure";
import LoginPage from "@ente/accounts/pages/login";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <LoginPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
