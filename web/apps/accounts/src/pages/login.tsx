import Page_ from "@ente/accounts/pages/login";
import { useAppContext } from "./_app";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
