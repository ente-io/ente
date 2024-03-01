import { t } from "i18next";
import { useContext, useState } from "react";

import { logoutUser } from "@ente/accounts/services/user";
import DeleteAccountModal from "components/DeleteAccountModal";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { AppContext } from "pages/_app";

export default function ExitSection() {
    const { setDialogMessage } = useContext(AppContext);

    const [deleteAccountModalView, setDeleteAccountModalView] = useState(false);

    const closeDeleteAccountModal = () => setDeleteAccountModalView(false);
    const openDeleteAccountModal = () => setDeleteAccountModalView(true);

    const confirmLogout = () => {
        setDialogMessage({
            title: t("LOGOUT_MESSAGE"),
            proceed: {
                text: t("LOGOUT"),
                action: logoutUser,
                variant: "critical",
            },
            close: { text: t("CANCEL") },
        });
    };

    return (
        <>
            <EnteMenuItem
                onClick={confirmLogout}
                color="critical"
                label={t("LOGOUT")}
                variant="secondary"
            />
            <EnteMenuItem
                onClick={openDeleteAccountModal}
                color="critical"
                variant="secondary"
                label={t("DELETE_ACCOUNT")}
            />
            <DeleteAccountModal
                open={deleteAccountModalView}
                onClose={closeDeleteAccountModal}
            />
        </>
    );
}
