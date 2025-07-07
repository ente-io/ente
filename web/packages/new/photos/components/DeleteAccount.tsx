import {
    Checkbox,
    FormControlLabel,
    FormGroup,
    Link,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { TitledMiniDialog } from "ente-base/components/MiniDialog";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { LoadingButton } from "ente-base/components/mui/LoadingButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import {
    DropdownInput,
    type DropdownOption,
} from "ente-new/photos/components/DropdownInput";
import {
    decryptDeleteAccountChallenge,
    deleteAccount,
    getAccountDeleteChallenge,
} from "ente-new/photos/services/user";
import { initiateEmail } from "ente-new/photos/utils/web";
import { useFormik } from "formik";
import { t } from "i18next";
import React, { useState } from "react";
import { Trans } from "react-i18next";

type DeleteAccountProps = ModalVisibilityProps & {
    /**
     * Called when the user should be authenticated again.
     *
     * Account deletion only proceeds if the promise returned by this function
     * is fulfilled.
     */
    onAuthenticateUser: () => Promise<void>;
};

export const DeleteAccount: React.FC<DeleteAccountProps> = ({
    open,
    onClose,
    ...rest
}) => (
    <TitledMiniDialog open={open} onClose={onClose} title={t("delete_account")}>
        <DeleteAccountDialogContents {...{ open, onClose }} {...rest} />
    </TitledMiniDialog>
);

/**
 * The contents of the {@link DeleteAccount} dialog.
 *
 * See: [Note: MUI dialog state] for why this is a separate component.
 */
const DeleteAccountDialogContents: React.FC<
    Omit<DeleteAccountProps, "open">
> = ({ onClose, onAuthenticateUser }) => {
    const { logout, showMiniDialog, onGenericError } = useBaseContext();

    const [acceptDataDeletion, setAcceptDataDeletion] = useState(false);
    const [loading, setLoading] = useState(false);

    const formik = useFormik({
        initialValues: { reason: "", feedback: "" },
        validate: ({ reason, feedback }) => {
            if (!reason) return { reason: t("required") };
            if (!feedback.trim().length) {
                return {
                    feedback:
                        reason == "found_another_service"
                            ? t("feedback_required_found_another_service")
                            : t("feedback_required"),
                };
            }
            return {};
        },
        onSubmit: async ({ reason, feedback }) => {
            feedback = feedback.trim();
            try {
                setLoading(true);
                const { allowDelete, encryptedChallenge } =
                    await getAccountDeleteChallenge();
                setLoading(false);

                if (allowDelete && encryptedChallenge) {
                    await onAuthenticateUser()
                        .then(confirmAccountDeletion)
                        .then(() =>
                            solveChallengeAndDeleteAccount(
                                encryptedChallenge,
                                reason,
                                feedback,
                            ),
                        );
                } else {
                    askToMailForDeletion();
                }
            } catch (e) {
                onGenericError(e);
                setLoading(false);
            }
        },
    });

    const confirmAccountDeletion = () =>
        new Promise<void>((resolve) =>
            showMiniDialog({
                title: t("delete_account"),
                message: <Trans i18nKey="delete_account_confirm_message" />,
                continue: {
                    text: t("delete"),
                    color: "critical",
                    action: resolve,
                },
            }),
        );

    const askToMailForDeletion = () => {
        const emailID = "account-deletion@ente.io";

        showMiniDialog({
            title: t("delete_account"),
            message: (
                <Trans
                    i18nKey="delete_account_manually_message"
                    components={{ a: <Link href={`mailto:${emailID}`} /> }}
                    values={{ emailID }}
                />
            ),
            continue: {
                text: t("delete"),
                color: "critical",
                action: () => initiateEmail(emailID),
            },
        });
    };

    const solveChallengeAndDeleteAccount = async (
        encryptedChallenge: string,
        reason: string,
        feedback: string,
    ) => {
        setLoading(true);
        const decryptedChallenge =
            await decryptDeleteAccountChallenge(encryptedChallenge);
        await deleteAccount(decryptedChallenge, reason, feedback);
        logout();
    };

    return (
        <form onSubmit={formik.handleSubmit}>
            <Stack sx={{ gap: "24px" }}>
                <Stack sx={{ gap: "4px" }}>
                    <Typography>{t("delete_account_reason_label")}</Typography>
                    <DropdownInput
                        options={deleteReasonOptions()}
                        placeholder={t("delete_account_reason_placeholder")}
                        selected={formik.values.reason}
                        onSelect={formik.handleChange("reason")}
                    />
                    {formik.touched.reason && formik.errors.reason && (
                        <Typography
                            variant="small"
                            sx={{ px: 1, color: "critical.main" }}
                        >
                            {formik.errors.reason}
                        </Typography>
                    )}
                </Stack>
                <FeedbackInput
                    value={formik.values.feedback}
                    onChange={formik.handleChange("feedback")}
                    errorMessage={
                        formik.touched.feedback
                            ? formik.errors.feedback
                            : undefined
                    }
                />
                <ConfirmationCheckboxInput
                    checked={acceptDataDeletion}
                    onChange={setAcceptDataDeletion}
                />
                <Stack sx={{ gap: "8px" }}>
                    <LoadingButton
                        type="submit"
                        fullWidth
                        color="critical"
                        disabled={!acceptDataDeletion}
                        loading={loading}
                    >
                        {t("delete_account_confirm")}
                    </LoadingButton>
                    <FocusVisibleButton
                        fullWidth
                        color="secondary"
                        onClick={onClose}
                    >
                        {t("cancel")}
                    </FocusVisibleButton>
                </Stack>
            </Stack>
        </form>
    );
};

/**
 * All of these must have a corresponding localized string nested under the
 * "delete_reason" key.
 */
const deleteReasons = [
    "missing_feature",
    "behaviour",
    "found_another_service",
    "not_listed",
] as const;

type DeleteReason = (typeof deleteReasons)[number];

const deleteReasonOptions = (): DropdownOption<DeleteReason>[] =>
    deleteReasons.map((reason) => ({
        label: t(`delete_reason.${reason}`),
        value: reason,
    }));

interface FeedbackInputProps {
    value: string;
    errorMessage?: string | undefined;
    onChange: (value: string) => void;
}

const FeedbackInput: React.FC<FeedbackInputProps> = ({
    value,
    onChange,
    errorMessage,
}) => (
    <Stack sx={{ gap: "4px" }}>
        <Typography>{t("delete_account_feedback_label")}</Typography>
        <TextField
            variant="standard"
            multiline
            rows={3}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={t("delete_account_feedback_placeholder")}
            sx={{
                border: "1px solid",
                borderColor: "stroke.faint",
                borderRadius: "8px",
                padding: "12px",
                ".MuiInputBase-formControl": {
                    "::before, ::after": { borderBottom: "none !important" },
                },
            }}
        />
        {errorMessage && (
            <Typography
                variant="small"
                sx={{ px: "8px", color: "critical.main" }}
            >
                {errorMessage}
            </Typography>
        )}
    </Stack>
);

interface ConfirmationCheckboxInputProps {
    checked: boolean;
    onChange: (value: boolean) => void;
}

const ConfirmationCheckboxInput: React.FC<ConfirmationCheckboxInputProps> = ({
    checked,
    onChange,
}) => (
    <FormGroup>
        <FormControlLabel
            control={
                <Checkbox
                    size="small"
                    checked={checked}
                    onChange={(e) => onChange(e.target.checked)}
                />
            }
            label={
                <Typography sx={{ color: "text.muted" }}>
                    {t("delete_account_confirm_checkbox_label")}
                </Typography>
            }
        />
    </FormGroup>
);
