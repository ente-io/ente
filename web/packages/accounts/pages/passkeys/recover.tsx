import React from "react";
import type { PageProps } from "../../types/page";
import TwoFactorRecoverPage from "../two-factor/recover";

const Page: React.FC<PageProps> = ({ appContext }) => (
    <TwoFactorRecoverPage appContext={appContext} twoFactorType="passkey" />
);

export default Page;
