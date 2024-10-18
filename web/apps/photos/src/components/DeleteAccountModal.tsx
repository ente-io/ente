import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import { AppContext } from "@/new/photos/types/context";
import { initiateEmail } from "@/new/photos/utils/web";
import {
    Checkbox,
    FormControlLabel,
    FormGroup,
    Link,
    Stack,
    TextField,
    Typography,
    type TypographyProps,
} from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { GalleryContext } from "pages/gallery";
import { useContext, useRef, useState } from "react";
import { Trans } from "react-i18next";
import { deleteAccount, getAccountDeleteChallenge } from "services/userService";
import { decryptDeleteAccountChallenge } from "utils/crypto";
import * as Yup from "yup";
import DropdownInput, { DropdownOption } from "./DropdownInput";

interface Iprops {
    onClose: () => void;
    open: boolean;
}

interface FormValues {
    reason: string;
    feedback: string;
}

const DeleteAccountModal = ({ open, onClose }: Iprops) => {
    const { showMiniDialog, onGenericError, logout } = useContext(AppContext);
    const { authenticateUser } = useContext(GalleryContext);

    const [loading, setLoading] = useState(false);
    const deleteAccountChallenge = useRef<string>();

    const [acceptDataDeletion, setAcceptDataDeletion] = useState(false);
    const reasonAndFeedbackRef = useRef<{ reason: string; feedback: string }>();

    const initiateDelete = async (
        { reason, feedback }: FormValues,
        { setFieldError }: FormikHelpers<FormValues>,
    ) => {
        try {
            feedback = feedback.trim();
            if (feedback.length === 0) {
                switch (reason) {
                    case "found_another_service":
                        setFieldError(
                            "feedback",
                            t("feedback_required_found_another_service"),
                        );
                        break;
                    default:
                        setFieldError("feedback", t("feedback_required"));
                }
                return;
            }
            setLoading(true);
            reasonAndFeedbackRef.current = { reason, feedback };
            const deleteChallengeResponse = await getAccountDeleteChallenge();
            deleteAccountChallenge.current =
                deleteChallengeResponse.encryptedChallenge;
            if (deleteChallengeResponse.allowDelete) {
                authenticateUser(confirmAccountDeletion);
            } else {
                askToMailForDeletion();
            }
        } catch (e) {
            onGenericError(e);
        } finally {
            setLoading(false);
        }
    };

    const confirmAccountDeletion = () =>
        showMiniDialog({
            title: t("delete_account"),
            message: <Trans i18nKey="delete_account_confirm_message" />,
            continue: {
                text: t("delete"),
                color: "critical",
                action: solveChallengeAndDeleteAccount,
            },
        });

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

    const solveChallengeAndDeleteAccount = async () => {
        const decryptedChallenge = await decryptDeleteAccountChallenge(
            deleteAccountChallenge.current,
        );
        const { reason, feedback } = reasonAndFeedbackRef.current;
        await deleteAccount(decryptedChallenge, reason, feedback);
        logout();
    };

    return (
        <TitledMiniDialog
            open={open}
            onClose={onClose}
            title={t("delete_account")}
        >
            <Formik<FormValues>
                initialValues={{
                    reason: "",
                    feedback: "",
                }}
                validationSchema={Yup.object().shape({
                    reason: Yup.string().required(t("required")),
                })}
                validateOnChange={false}
                validateOnBlur={false}
                onSubmit={initiateDelete}
            >
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                }): JSX.Element => (
                    <form noValidate onSubmit={handleSubmit}>
                        <Stack spacing={"24px"}>
                            <DropdownInput
                                options={deleteReasonOptions()}
                                label={t("delete_account_reason_label")}
                                placeholder={t(
                                    "delete_account_reason_placeholder",
                                )}
                                selected={values.reason}
                                setSelected={handleChange("reason")}
                                messageProps={{ color: "critical.main" }}
                                message={errors.reason}
                            />
                            <MultilineInput
                                label={t("delete_account_feedback_label")}
                                placeholder={t(
                                    "delete_account_feedback_placeholder",
                                )}
                                value={values.feedback}
                                onChange={handleChange("feedback")}
                                message={errors.feedback}
                                messageProps={{ color: "critical.main" }}
                                rowCount={3}
                            />
                            <CheckboxInput
                                checked={acceptDataDeletion}
                                onChange={setAcceptDataDeletion}
                                label={t(
                                    "delete_account_confirm_checkbox_label",
                                )}
                            />
                            <Stack spacing={"8px"}>
                                <LoadingButton
                                    type="submit"
                                    size="large"
                                    color="critical"
                                    disabled={!acceptDataDeletion}
                                    loading={loading}
                                >
                                    {t("delete_account_confirm")}
                                </LoadingButton>
                                <FocusVisibleButton
                                    size="large"
                                    color={"secondary"}
                                    onClick={onClose}
                                >
                                    {t("cancel")}
                                </FocusVisibleButton>
                            </Stack>
                        </Stack>
                    </form>
                )}
            </Formik>
        </TitledMiniDialog>
    );
};

export default DeleteAccountModal;

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

interface MultilineInputProps {
    label: string;
    labelProps?: TypographyProps;
    message?: string;
    messageProps?: TypographyProps;
    placeholder?: string;
    value: string;
    rowCount: number;
    onChange: (value: string) => void;
}

function MultilineInput({
    label,
    labelProps,
    message,
    messageProps,
    placeholder,
    value,
    rowCount,
    onChange,
}: MultilineInputProps) {
    return (
        <Stack spacing={"4px"}>
            <Typography {...labelProps}>{label}</Typography>
            <TextField
                variant="standard"
                multiline
                rows={rowCount}
                value={value}
                onChange={(e) => onChange(e.target.value)}
                placeholder={placeholder}
                sx={(theme) => ({
                    border: "1px solid",
                    borderColor: theme.colors.stroke.faint,
                    borderRadius: "8px",
                    padding: "12px",
                    ".MuiInputBase-formControl": {
                        "::before, ::after": {
                            borderBottom: "none !important",
                        },
                    },
                })}
            />
            <Typography
                px={"8px"}
                variant="small"
                color="text.secondary"
                {...messageProps}
            >
                {message}
            </Typography>
        </Stack>
    );
}

interface CheckboxInputProps {
    disabled?: boolean;
    checked: boolean;
    onChange: (value: boolean) => void;
    label: string;
    labelProps?: TypographyProps;
}

function CheckboxInput({
    disabled,
    checked,
    onChange,
    label,
    labelProps,
}: CheckboxInputProps) {
    return (
        <FormGroup sx={{ width: "100%" }}>
            <FormControlLabel
                control={
                    <Checkbox
                        size="small"
                        disabled={disabled}
                        checked={checked}
                        onChange={(e) => onChange(e.target.checked)}
                        color="accent"
                    />
                }
                label={
                    <Typography color="text.secondary" {...labelProps}>
                        {label}
                    </Typography>
                }
            />
        </FormGroup>
    );
}
