import { ensure } from "@/utils/ensure";
import TwoFactorRecoverPage from "@ente/accounts/pages/two-factor/recover";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <TwoFactorRecoverPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
