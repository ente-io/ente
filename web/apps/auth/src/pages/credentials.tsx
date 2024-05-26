import { ensure } from "@/utils/ensure";
import Page_ from "@ente/accounts/pages/credentials";
import { useContext } from "react";
import { AppContext } from "./_app";

const Page = () => <Page_ appContext={ensure(useContext(AppContext))} />;

export default Page;
