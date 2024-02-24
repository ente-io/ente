import { useContext, useEffect, useState } from "react";

import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import VerifyMasterPasswordForm, {
    VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import { logError } from "@ente/shared/sentry";
import { getData, LS_KEYS } from "@ente/shared/storage/localStorage";
import { KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { AppContext } from "pages/_app";
interface Iprops {
    open: boolean;
    onClose: () => void;
    onAuthenticate: () => void;
}

export default function AuthenticateUserModal({
    open,
    onClose,
    onAuthenticate,
}: Iprops) {
    const { setDialogMessage } = useContext(AppContext);
    const [user, setUser] = useState<User>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t("ERROR"),
            close: { variant: "critical" },
            content: t("UNKNOWN_ERROR"),
        });

    useEffect(() => {
        const main = async () => {
            try {
                const user = getData(LS_KEYS.USER);
                if (!user) {
                    throw Error("User not found");
                }
                setUser(user);
                const keyAttributes = getData(LS_KEYS.KEY_ATTRIBUTES);
                if (
                    (!user?.token && !user?.encryptedToken) ||
                    (keyAttributes && !keyAttributes.memLimit)
                ) {
                    throw Error("User not logged in");
                } else if (!keyAttributes) {
                    throw Error("Key attributes not found");
                } else {
                    setKeyAttributes(keyAttributes);
                }
            } catch (e) {
                logError(e, "AuthenticateUserModal initialization failed");
                onClose();
                somethingWentWrong();
            }
        };
        main();
    }, []);

    const useMasterPassword: VerifyMasterPasswordFormProps["callback"] =
        async () => {
            onClose();
            onAuthenticate();
        };

    return (
        <DialogBoxV2
            open={open}
            onClose={onClose}
            sx={{ position: "absolute" }}
            attributes={{
                title: t("PASSWORD"),
            }}
        >
            <VerifyMasterPasswordForm
                buttonText={t("AUTHENTICATE")}
                callback={useMasterPassword}
                user={user}
                keyAttributes={keyAttributes}
                submitButtonProps={{ sx: { mb: 0 } }}
            />
        </DialogBoxV2>
    );
}
