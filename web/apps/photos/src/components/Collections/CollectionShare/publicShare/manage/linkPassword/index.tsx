import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useState } from "react";
import { Collection, PublicURL, UpdatePublicURL } from "types/collection";
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
    const appContext = useContext(AppContext);
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
        appContext.setDialogMessage({
            title: t("DISABLE_PASSWORD"),
            content: t("DISABLE_PASSWORD_MESSAGE"),
            close: { text: t("CANCEL") },
            proceed: {
                text: t("DISABLE"),
                action: () =>
                    updatePublicShareURLHelper({
                        collectionID: collection.id,
                        disablePassword: true,
                    }),
                variant: "critical",
            },
        });
    };

    return (
        <>
            <EnteMenuItem
                label={t("LINK_PASSWORD_LOCK")}
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
