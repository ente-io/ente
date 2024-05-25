import { ensure } from "@/utils/ensure";
import TwoFactorSetupPage from "@ente/accounts/pages/two-factor/setup";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <TwoFactorSetupPage appContext={appContext} appName={APPS.AUTH} />;
}

export default Page;
