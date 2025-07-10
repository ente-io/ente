import { VerifyMasterPasswordForm } from "ente-accounts/components/VerifyMasterPasswordForm";
import { checkSessionValidity } from "ente-accounts/services/session";
import {
    ensureLocalUser,
    ensureSavedKeyAttributes,
    type KeyAttributes,
    type LocalUser,
} from "ente-accounts/services/user";
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
    ...rest
}) => (
    <TitledMiniDialog
        open={open}
        onClose={onClose}
        sx={{ position: "absolute" }}
        title={t("password")}
    >
        <AuthenticateUserDialogContents {...{ open, onClose }} {...rest} />
    </TitledMiniDialog>
);

/**
 * The contents of the {@link AuthenticateUser} dialog.
 *
 * See: [Note: MUI dialog state] for why this is a separate component.
 */
const AuthenticateUserDialogContents: React.FC<AuthenticateUserProps> = ({
    open,
    onClose,
    onAuthenticate,
}) => {
    const { logout, showMiniDialog } = useBaseContext();

    const [user, setUser] = useState<LocalUser | undefined>();
    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >(undefined);

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
    }, [logout, showMiniDialog, onClose]);

    useEffect(() => {
        setUser(ensureLocalUser());
        setKeyAttributes(ensureSavedKeyAttributes());
    }, []);

    useEffect(() => {
        // Do a non-blocking validation of the session whenever we show the
        // dialog to the user.
        if (open) void validateSession();
    }, [open, validateSession]);

    // They'll be read from disk shortly.
    if (!user || !keyAttributes) return <></>;

    return (
        <VerifyMasterPasswordForm
            userEmail={user.email}
            keyAttributes={keyAttributes}
            submitButtonTitle={t("authenticate")}
            onVerify={() => {
                onClose();
                onAuthenticate();
            }}
        />
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
