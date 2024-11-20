import Page_ from "@/accounts/pages/two-factor/recover";
import { useAppContext } from "types/context";

const Page = () => <Page_ appContext={useAppContext()} twoFactorType="totp" />;

export default Page;
