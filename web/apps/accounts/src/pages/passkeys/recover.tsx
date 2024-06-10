import Page_ from "@ente/accounts/pages/two-factor/recover";
import { useAppContext } from "../_app";

// This page is for when trying to reset the passkey verification within the
// accounts app itself. More commonly, this happens in the auth/photos app.
//
// See: [Note: Finish passkey flow in the requesting app]

const Page = () => (
    <Page_ appContext={useAppContext()} twoFactorType="passkey" />
);

export default Page;
