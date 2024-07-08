import Page_ from "@/accounts/pages/two-factor/verify";
import { useAppContext } from "../_app";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
