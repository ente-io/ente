import { ensure } from "@/utils/ensure";
import ChangeEmailPage from "@ente/accounts/pages/change-email";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <ChangeEmailPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
