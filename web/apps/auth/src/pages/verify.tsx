import { ensure } from "@/utils/ensure";
import VerifyPage from "@ente/accounts/pages/verify";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <VerifyPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
