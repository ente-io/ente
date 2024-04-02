import { TwoFactorType } from "@ente/accounts/constants/twofactor";
import { SetDialogBoxAttributesV2 } from "@ente/shared/components/DialogBoxV2/types";
import { NextRouter } from "next/router";
import { APPS } from "./constants";

export interface PageProps {
    appContext: {
        showNavBar: (show: boolean) => void;
        isMobile: boolean;
        setDialogBoxAttributesV2: SetDialogBoxAttributesV2;
    };
    router: NextRouter;
    appName: APPS;
    twoFactorType?: TwoFactorType;
}
