import Page_ from "@/accounts/pages/two-factor/verify";
import { useAppContext } from "types/context";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
