import Page_ from "@/accounts/pages/generate";
import { useAppContext } from "types/context";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
