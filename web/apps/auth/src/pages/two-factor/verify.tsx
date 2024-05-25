import { ensure } from "@/utils/ensure";
import TwoFactorVerifyPage from "@ente/accounts/pages/two-factor/verify";
import { APPS } from "@ente/shared/apps/constants";
import React, { useContext } from "react";
import { AppContext } from "../_app";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <TwoFactorVerifyPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
