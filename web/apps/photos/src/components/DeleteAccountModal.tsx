import { initiateEmail } from "@/new/photos/utils/web";
import log from "@/next/log";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import EnteButton from "@ente/shared/components/EnteButton";
import { Button, Link, Stack } from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { GalleryContext } from "pages/gallery";
import { useContext, useEffect, useRef, useState } from "react";
import { Trans } from "react-i18next";
import { deleteAccount, getAccountDeleteChallenge } from "services/userService";
import { preloadImage } from "utils/common";
import { decryptDeleteAccountChallenge } from "utils/crypto";
import * as Yup from "yup";
import { CheckboxInput } from "./CheckboxInput";
import DropdownInput, { DropdownOption } from "./DropdownInput";
import MultilineInput from "./MultilineInput";

interface Iprops {
    onClose: () => void;
    open: boolean;
}

interface FormValues {
    reason: string;
    feedback: string;
}

const DeleteAccountModal = ({ open, onClose }: Iprops) => {
    const { setDialogBoxAttributesV2, isMobile, logout } =
        useContext(AppContext);
    const { authenticateUser } = useContext(GalleryContext);
    const [loading, setLoading] = useState(false);
    const deleteAccountChallenge = useRef<string>();

    const [acceptDataDeletion, setAcceptDataDeletion] = useState(false);
    const reasonAndFeedbackRef = useRef<{ reason: string; feedback: string }>();

    useEffect(() => {
        preloadImage("/images/delete-account");
    }, []);

    const somethingWentWrong = () =>
        setDialogBoxAttributesV2({
            title: t("ERROR"),
            close: { variant: "critical" },
            content: t("UNKNOWN_ERROR"),
        });

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
            log.error("Error while initiating account deletion", e);
            somethingWentWrong();
        } finally {
            setLoading(false);
        }
    };

    const confirmAccountDeletion = () => {
        setDialogBoxAttributesV2({
            title: t("delete_account"),
            content: <Trans i18nKey="delete_account_confirm_message" />,
            proceed: {
                text: t("DELETE"),
                action: solveChallengeAndDeleteAccount,
                variant: "critical",
            },
            close: { text: t("CANCEL") },
        });
    };

    const askToMailForDeletion = () => {
        const emailID = "account-deletion@ente.io";

        setDialogBoxAttributesV2({
            title: t("delete_account"),
            content: (
                <Trans
                    i18nKey="delete_account_manually_message"
                    components={{ a: <Link href={`mailto:${emailID}`} /> }}
                    values={{ emailID }}
                />
            ),
            proceed: {
                text: t("DELETE"),
                action: () => initiateEmail(emailID),
                variant: "critical",
            },
            close: { text: t("CANCEL") },
        });
    };

    const solveChallengeAndDeleteAccount = async (
        setLoading: (value: boolean) => void,
    ) => {
        try {
            setLoading(true);
            const decryptedChallenge = await decryptDeleteAccountChallenge(
                deleteAccountChallenge.current,
            );
            const { reason, feedback } = reasonAndFeedbackRef.current;
            await deleteAccount(decryptedChallenge, reason, feedback);
            logout();
        } catch (e) {
            log.error("solveChallengeAndDeleteAccount failed", e);
            somethingWentWrong();
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            <DialogBoxV2
                fullWidth
                open={open}
                onClose={onClose}
                fullScreen={isMobile}
                attributes={{
                    title: t("delete_account"),
                    secondary: {
                        action: onClose,
                        text: t("CANCEL"),
                    },
                }}
            >
                <Formik<FormValues>
                    initialValues={{
                        reason: "",
                        feedback: "",
                    }}
                    validationSchema={Yup.object().shape({
                        reason: Yup.string().required(t("REQUIRED")),
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
                                    <EnteButton
                                        type="submit"
                                        size="large"
                                        color="critical"
                                        disabled={!acceptDataDeletion}
                                        loading={loading}
                                    >
                                        {t("delete_account_confirm")}
                                    </EnteButton>
                                    <Button
                                        size="large"
                                        color={"secondary"}
                                        onClick={onClose}
                                    >
                                        {t("CANCEL")}
                                    </Button>
                                </Stack>
                            </Stack>
                        </form>
                    )}
                </Formik>
            </DialogBoxV2>
        </>
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
