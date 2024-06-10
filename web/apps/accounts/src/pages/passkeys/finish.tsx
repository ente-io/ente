import Page_ from "@ente/accounts/pages/passkeys/finish";
import { useAppContext } from "../_app";

// This page is for when trying to finish the passkey verification within the
// accounts app itself. More commonly, this happens in the auth/photos app.
//
// See: [Note: Finish passkey flow in the requesting app]
const Page = () => <Page_ appContext={useAppContext()} />;

export default Page;
