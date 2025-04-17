import type { MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { t } from "i18next";

/**
 * {@link MiniDialogAttributes} for showing asking the user to login again when
 * their session has expired.
 *
 * There is one button, which allows them to logout.
 *
 * @param onLogin Called when the user presses the "Login" button on the error
 * dialog.
 */
export const sessionExpiredDialogAttributes = (
    onLogin: () => void,
): MiniDialogAttributes => ({
    title: t("session_expired"),
    message: t("session_expired_message"),
    nonClosable: true,
    nonReplaceable: true,
    continue: { text: t("login"), action: onLogin },
    cancel: false,
});
