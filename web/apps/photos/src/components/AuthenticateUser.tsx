import { VerifyMasterPasswordForm } from "ente-accounts/components/VerifyMasterPasswordForm";
import { getData } from "ente-accounts/services/accounts-db";
import { checkSessionValidity } from "ente-accounts/services/session";
import type { KeyAttributes, User } from "ente-accounts/services/user";
import {
    TitledMiniDialog,
    type MiniDialogAttributes,
} from "ente-base/components/MiniDialog";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { t } from "i18next";
import { useCallback, useEffect, useState } from "react";

type AuthenticateUserProps = ModalVisibilityProps & {
    /**
     * Called when the user successfully reauthenticates themselves.
     */
    onAuthenticate: () => void;
};

/**
 * A dialog for reauthenticating the logged in user by prompting them for their
 * password.
 *
 * This is used as precursor to performing various sensitive or locked actions.
 */
export const AuthenticateUser: React.FC<AuthenticateUserProps> = ({
    open,
    onClose,
    onAuthenticate,
}) => {
    const { logout, showMiniDialog, onGenericError } = useBaseContext();
    const [user, setUser] = useState<User>();
    const [keyAttributes, setKeyAttributes] = useState<KeyAttributes>();

    // This is a altered version of the check we do on the password verification
    // screen, except here it don't try to overwrite local state and instead
    // just request the user to login again if we detect that their password has
    // changed on a different device and they haven't unlocked even once since
    // then on this device.
    const validateSession = useCallback(async () => {
        try {
            const session = await checkSessionValidity();
            if (session.status != "valid") {
                onClose();
                showMiniDialog(
                    passwordChangedElsewhereDialogAttributes(logout),
                );
            }
        } catch (e) {
            // Ignore errors since we shouldn't be logging the user out for
            // potentially transient issues.
            log.warn("Ignoring error when determining session validity", e);
        }
    }, [logout, showMiniDialog]);

    useEffect(() => {
        const main = async () => {
            try {
                const user = getData("user");
                if (!user) {
                    throw Error("User not found");
                }
                setUser(user);
                const keyAttributes = getData("keyAttributes");
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
                onClose();
                onGenericError(e);
            }
        };
        main();
    }, []);

    useEffect(() => {
        // Do a non-blocking validation of the session, but show the dialog to
        // the user.
        if (open) void validateSession();
    }, [open]);

    return (
        <TitledMiniDialog
            open={open}
            onClose={onClose}
            sx={{ position: "absolute" }}
            title={t("password")}
        >
            <VerifyMasterPasswordForm
                user={user}
                keyAttributes={keyAttributes}
                submitButtonTitle={t("authenticate")}
                onVerify={() => {
                    onClose();
                    onAuthenticate();
                }}
            />
        </TitledMiniDialog>
    );
};

/**
 * Attributes for a dialog box that informs the user that their password was
 * changed on a different device, and they the need to login again to be able to
 * use the new one. Cancellable.
 *
 * @param onLogin Called if the user chooses the login option.
 */
const passwordChangedElsewhereDialogAttributes = (
    onLogin: () => void,
): MiniDialogAttributes => ({
    title: t("password_changed_elsewhere"),
    message: t("password_changed_elsewhere_message"),
    continue: { text: t("login"), action: onLogin },
    cancel: false,
});
