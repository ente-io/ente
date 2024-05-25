import { ensure } from "@/utils/ensure";
import ChangePasswordPage from "@ente/accounts/pages/change-password";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <ChangePasswordPage appContext={appContext} appName={APPS.AUTH} />;
}

export default Page;
