import { Input, TextField } from "@mui/material";
import type { SRPAttributes } from "ente-accounts/services/srp-remote";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import { ShowHidePasswordInputAdornment } from "ente-base/components/mui/PasswordInputAdornment";
import { sharedCryptoWorker } from "ente-base/crypto";
import log from "ente-base/log";
import { CustomError } from "ente-shared/error";
import type { KeyAttributes, User } from "ente-shared/user/types";
import { useFormik } from "formik";
import { t } from "i18next";
import { useCallback, useState } from "react";

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
     * This function can throw an `CustomError.TWO_FACTOR_ENABLED` to signal to
     * the form that some other form of second factor is enabled and the user
     * has been redirected to a two factor verification page.
     *
     * This function can throw an `CustomError.INCORRECT_PASSWORD_OR_NO_ACCOUNT`
     * to signal that either that the password is incorrect, or no account with
     * the provided email exists.
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
     * the kek derived from their passphrase.
     *
     * @param kek The key used for encrypting the user's master key.
     *
     * @param keyAttributes The user's key attributes (either those that we
     * started with, or those that we fetched on the way using
     * {@link getKeyAttributes}).
     *
     * @param passphrase The plaintext passphrase. This can be used during login
     * to derive another encrypted key using interactive mem/ops limits for
     * faster reauthentication after the initial login.
     */
    onVerify: (
        key: string,
        kek: string,
        keyAttributes: KeyAttributes,
        passphrase: string,
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

            await verifyPassphrase(password, setPasswordFieldError);
        },
    });

    const verifyPassphrase = async (
        passphrase: string,
        setFieldError: (message: string) => void,
    ) => {
        try {
            const cryptoWorker = await sharedCryptoWorker();
            let kek: string;
            if (srpAttributes) {
                try {
                    kek = await cryptoWorker.deriveKey(
                        passphrase,
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
                    kek = await cryptoWorker.deriveKey(
                        passphrase,
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
                keyAttributes = await getKeyAttributes(kek);
            }
            if (!keyAttributes) {
                throw Error("couldn't get key attributes");
            }

            try {
                const key = await cryptoWorker.decryptB64(
                    keyAttributes.encryptedKey,
                    keyAttributes.keyDecryptionNonce,
                    kek,
                );
                onVerify(key, kek, keyAttributes, passphrase);
            } catch (e) {
                log.error("user entered a wrong password", e);
                throw Error(CustomError.INCORRECT_PASSWORD);
            }
        } catch (e) {
            if (e instanceof Error) {
                if (e.message === CustomError.TWO_FACTOR_ENABLED) {
                    // two factor enabled, user has been redirected to two factor page
                    return;
                }
                log.error("failed to verify passphrase", e);
                switch (e.message) {
                    case CustomError.INCORRECT_PASSWORD:
                        setFieldError(t("incorrect_password"));
                        break;
                    case CustomError.INCORRECT_PASSWORD_OR_NO_ACCOUNT:
                        setFieldError(t("incorrect_password_or_no_account"));
                        break;
                    default:
                        setFieldError(t("generic_error"));
                }
            } else {
                log.error("failed to verify passphrase", e);
            }
        }
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
