import { ensure } from "@/utils/ensure";
import GeneratePage from "@ente/accounts/pages/generate";
import { APPS } from "@ente/shared/apps/constants";
import { AppContext } from "pages/_app";
import React, { useContext } from "react";

const Page: React.FC = () => {
    const appContext = ensure(useContext(AppContext));
    return <GeneratePage appContext={appContext} appName={APPS.AUTH} />;
};

export default Page;
