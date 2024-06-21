import log from "@/next/log";
import { checkSessionValidity } from "@ente/accounts/services/session";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import { dismissableSessionExpiredDialogAttributes } from "@ente/shared/components/LoginComponents";
import VerifyMasterPasswordForm, {
    type VerifyMasterPasswordFormProps,
} from "@ente/shared/components/VerifyMasterPasswordForm";
import { LS_KEYS, getData } from "@ente/shared/storage/localStorage";
import type { KeyAttributes, User } from "@ente/shared/user/types";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useCallback, useContext, useEffect, useState } from "react";

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
    const { setDialogMessage, setDialogBoxAttributesV2, logout } =
        useContext(AppContext);
    const [user, setUser] = useState<User>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    const somethingWentWrong = () =>
        setDialogMessage({
            title: t("ERROR"),
            close: { variant: "critical" },
            content: t("UNKNOWN_ERROR"),
        });

    // This is a altered version of the check we do on the password
    // verification screen, except here it don't try to overwrite local
    // state and instead just request the user to login again if we detect
    // that their password has changed on a different device and they
    // haven't unlocked even once since then on this device.
    const validateSession = useCallback(async () => {
        try {
            const session = await checkSessionValidity();
            if (session.status != "valid") {
                setDialogBoxAttributesV2(
                    dismissableSessionExpiredDialogAttributes(logout),
                );
            }
        } catch (e) {
            // Ignore errors since we shouldn't be logging the user out for
            // potentially transient issues.
            log.warn("Ignoring error when determining session validity", e);
        }
    }, [setDialogBoxAttributesV2, logout]);

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
                await validateSession();
            } catch (e) {
                log.error("AuthenticateUserModal initialization failed", e);
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
                title: t("password"),
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
