import type {
    Collection,
    PublicURL,
    UpdatePublicURL,
} from "@/media/collection";
import { useAppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { t } from "i18next";
import { useState } from "react";
import { PublicLinkSetPassword } from "./setPassword";

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManageLinkPassword({
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
}: Iprops) {
    const { showMiniDialog } = useAppContext();
    const [changePasswordView, setChangePasswordView] = useState(false);

    const closeConfigurePassword = () => setChangePasswordView(false);

    const handlePasswordChangeSetting = async () => {
        if (publicShareProp.passwordEnabled) {
            await confirmDisablePublicUrlPassword();
        } else {
            setChangePasswordView(true);
        }
    };

    const confirmDisablePublicUrlPassword = async () => {
        showMiniDialog({
            title: t("disable_password"),
            message: t("disable_password_message"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        disablePassword: true,
                    }),
            },
        });
    };

    return (
        <>
            <EnteMenuItem
                label={t("link_password_lock")}
                onClick={handlePasswordChangeSetting}
                checked={!!publicShareProp?.passwordEnabled}
                variant="toggle"
            />
            <PublicLinkSetPassword
                open={changePasswordView}
                onClose={closeConfigurePassword}
                collection={collection}
                publicShareProp={publicShareProp}
                updatePublicShareURLHelper={updatePublicShareURLHelper}
                setChangePasswordView={setChangePasswordView}
            />
        </>
    );
}
