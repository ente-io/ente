import { Input, TextField } from "@mui/material";
import {
    srpVerificationUnauthorizedErrorMessage,
    type SRPAttributes,
} from "ente-accounts/services/srp";
import type { KeyAttributes } from "ente-accounts/services/user";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { decryptBox, deriveKey } from "ente-base/crypto";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import { useCallback, useState } from "react";

export interface VerifyMasterPasswordFormProps {
    /**
     * The email of the user whose password we're trying to verify.
     */
    userEmail: string;
    /**
     * The user's SRP attributes.
     *
     * The SRP attributes are used to derive the KEK from the user's password.
     * If they are not present, the {@link keyAttributes} will be used instead.
     *
     * At least one of {@link srpAttributes} and {@link keyAttributes} must be
     * present, otherwise the verification will fail.
     */
    srpAttributes?: SRPAttributes;
    /**
     * The user's key attributes.
     *
     * If they are present, they are used to derive the KEK from the user's
     * password when {@link srpAttributes} are not present. This is the case
     * when the user has already logged in (or signed up) on this client before,
     * and is now doing a reauthentication.
     *
     * If they are not present, then {@link getKeyAttributes} must be present
     * and will be used to obtain the user's key attributes. This is the case
     * when the user is logging into a new client.
     */
    keyAttributes: KeyAttributes | undefined;
    /**
     * A callback invoked when the form wants to get {@link KeyAttributes}.
     *
     * It is only provided during the login flow, where we do not have
     * {@link keyAttributes} already available for the user. In case the form is
     * used for reauthenticating the user after they've already logged in, then
     * this function will not be provided.
     *
     * @returns The user's key attributes obtained from remote, or
     * "redirecting-second-factor" if the user has an additional second factor
     * verification required and the app is redirecting there.
     *
     * @throws A Error with message
     * {@link srpVerificationUnauthorizedErrorMessage} to signal that either
     * that the password is incorrect, or no account with the provided email
     * exists.
     */
    getKeyAttributes?: (
        srpAttributes: SRPAttributes,
        kek: string,
    ) => Promise<KeyAttributes | "redirecting-second-factor" | undefined>;
    /**
     * The title of the submit button on the form.
     */
    submitButtonTitle: string;
    /**
     * The callback invoked with the verified password, and all the other
     * auxillary information that was ascertained when verifying it.
     *
     * @param key The user's master key obtained after decrypting it by using
     * the KEK derived from their password.
     *
     * @param kek The key used for encrypting the user's master key.
     *
     * @param keyAttributes The user's key attributes (either those that we
     * started with, or those that we fetched on the way using
     * {@link getKeyAttributes}).
     *
     * @param password The plaintext password. This can be used during login to
     * derive another encrypted key using interactive mem/ops limits for faster
     * reauthentication after the initial login.
     */
    onVerify: (
        key: string,
        kek: string,
        keyAttributes: KeyAttributes,
        password: string,
    ) => void;
}

/**
 * A form with a text field that can be used to ask the user to verify their
 * password.
 *
 * We use it both during the initial authentication (the "/credentials" page,
 * shown when logging in, or reopening the web app in a new tab), and when the
 * user is trying to perform a sensitive action when already logged in and
 * having a session (the {@link AuthenticateUser} component).
 */
export const VerifyMasterPasswordForm: React.FC<
    VerifyMasterPasswordFormProps
> = ({
    userEmail,
    keyAttributes,
    srpAttributes,
    getKeyAttributes,
    onVerify,
    submitButtonTitle,
}) => {
    const [showPassword, setShowPassword] = useState(false);

    const handleToggleShowHidePassword = useCallback(
        () => setShowPassword((show) => !show),
        [],
    );

    const formik = useFormik({
        initialValues: { password: "" },
        onSubmit: async ({ password }, { setFieldError }) => {
            const setPasswordFieldError = (message: string) =>
                setFieldError("password", message);

            if (!password) {
                setPasswordFieldError(t("required"));
                return;
            }

            try {
                await verifyPassword(password, setPasswordFieldError);
            } catch (e) {
                log.error("Failed to to verify password", e);
                setPasswordFieldError(t("generic_error"));
            }
        },
    });

    const verifyPassword = async (
        password: string,
        setFieldError: (message: string) => void,
    ) => {
        let kek: string;
        if (srpAttributes) {
            try {
                kek = await deriveKey(
                    password,
                    srpAttributes.kekSalt,
                    srpAttributes.opsLimit,
                    srpAttributes.memLimit,
                );
            } catch (e) {
                log.error("Failed to derive kek", e);
                setFieldError(t("weak_device_hint"));
                return;
            }
        } else if (keyAttributes) {
            try {
                kek = await deriveKey(
                    password,
                    keyAttributes.kekSalt,
                    keyAttributes.opsLimit,
                    keyAttributes.memLimit,
                );
            } catch (e) {
                log.error("Failed to derive kek", e);
                setFieldError(t("weak_device_hint"));
                return;
            }
        } else throw new Error("Both SRP and key attributes are missing");

        if (!keyAttributes && getKeyAttributes && srpAttributes) {
            try {
                const result = await getKeyAttributes(srpAttributes, kek);
                if (result == "redirecting-second-factor") {
                    // Two factor enabled, user has been redirected to the
                    // corresponding second factor verification page.
                    return;
                } else {
                    keyAttributes = result;
                }
            } catch (e) {
                if (
                    e instanceof Error &&
                    e.message == srpVerificationUnauthorizedErrorMessage
                ) {
                    log.error("Incorrect password or no account", e);
                    setFieldError(t("incorrect_password_or_no_account"));
                    return;
                }
                throw e;
            }
        }

        if (!keyAttributes) throw Error("Couldn't get key attributes");

        let key: string;
        try {
            key = await decryptBox(
                {
                    encryptedData: keyAttributes.encryptedKey,
                    nonce: keyAttributes.keyDecryptionNonce,
                },
                kek,
            );
        } catch {
            setFieldError(t("incorrect_password"));
            return;
        }

        onVerify(key, kek, keyAttributes, password);
    };

    return (
        <form onSubmit={formik.handleSubmit}>
            <Input
                sx={{ display: "none" }}
                name="email"
                autoComplete="username"
                type="email"
                value={userEmail}
            />
            <TextField
                name="password"
                value={formik.values.password}
                onChange={formik.handleChange}
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                label={t("password")}
                fullWidth
                autoFocus
                margin="normal"
                disabled={formik.isSubmitting}
                error={!!formik.errors.password}
                helperText={formik.errors.password ?? " "}
                slotProps={{
                    input: {
                        endAdornment: (
                            <ShowHidePasswordInputAdornment
                                showPassword={showPassword}
                                onToggle={handleToggleShowHidePassword}
                            />
                        ),
                    },
                }}
            />
            <LoadingButton
                fullWidth
                type="submit"
                loading={formik.isSubmitting}
                color={"accent"}
            >
                {submitButtonTitle}
            </LoadingButton>
        </form>
    );
};
