import { ensure } from "@/utils/ensure";
import SignupPage from "@ente/accounts/pages/signup";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <SignupPage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
