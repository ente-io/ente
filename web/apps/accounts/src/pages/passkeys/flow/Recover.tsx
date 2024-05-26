import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import RecoverPage from "@ente/accounts/pages/two-factor/recover";
import { useAppContext } from "../../_app";

const Page = () => (
    <RecoverPage
        appContext={useAppContext()}
        twoFactorType={TwoFactorType.PASSKEY}
    />
);

export default Page;
