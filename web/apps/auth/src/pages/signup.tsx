import Page_ from "@/accounts/pages/signup";
import { useAppContext } from "./_app";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
