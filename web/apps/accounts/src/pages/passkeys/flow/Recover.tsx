import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import Page_ from "@ente/accounts/pages/two-factor/recover";
import { useAppContext } from "../../_app";

const Page = () => (
    <Page_ appContext={useAppContext()} twoFactorType={TwoFactorType.PASSKEY} />
);

export default Page;
