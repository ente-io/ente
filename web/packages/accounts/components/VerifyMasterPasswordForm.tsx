import { Input, TextField } from "@mui/material";
import {
    srpVerificationUnauthorizedErrorMessage,
    type SRPAttributes,
} from "ente-accounts/services/srp";
import type { KeyAttributes, User } from "ente-accounts/services/user";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { decryptBox, deriveKey } from "ente-base/crypto";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import { useCallback, useState } from "react";
import { twoFactorEnabledErrorMessage } from "./utils/second-factor-choice";

export interface VerifyMasterPasswordFormProps {
    /**
     * The user whose password we're trying to verify.
     */
    user: User | undefined;
    /**
     * The user's key attributes.
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
     * @throws A Error with message {@link twoFactorEnabledErrorMessage} to
     * signal to the form that some other form of second factor is enabled and
     * the user has been redirected to a two factor verification page.
     *
     * @throws A Error with message
     * {@link srpVerificationUnauthorizedErrorMessage} to signal that either
     * that the password is incorrect, or no account with the provided email
     * exists.
     */
    getKeyAttributes?: (kek: string) => Promise<KeyAttributes | undefined>;
    /**
     * The user's SRP attributes.
     */
    srpAttributes?: SRPAttributes;
    /**
     * The title of the submit button no the form.
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
 */
export const VerifyMasterPasswordForm: React.FC<
    VerifyMasterPasswordFormProps
> = ({
    user,
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

        if (!keyAttributes && typeof getKeyAttributes == "function") {
            try {
                keyAttributes = await getKeyAttributes(kek);
            } catch (e) {
                if (e instanceof Error) {
                    switch (e.message) {
                        case twoFactorEnabledErrorMessage:
                            // Two factor enabled, user has been redirected to
                            // the two-factor verification page.
                            return;

                        case srpVerificationUnauthorizedErrorMessage:
                            log.error("Incorrect password or no account", e);
                            setFieldError(
                                t("incorrect_password_or_no_account"),
                            );
                            return;
                    }
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
                value={user?.email}
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
