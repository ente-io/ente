import Page_ from "@/accounts/pages/two-factor/setup";
import { useAppContext } from "@/new/photos/types/context";

const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
