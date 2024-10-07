import InvalidInputMessage from "@/accounts/components/two-factor/InvalidInputMessage";
import { wait } from "@/utils/promise";
import {
    CenteredFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import SubmitButton from "@ente/shared/components/SubmitButton";
import { Box, Typography } from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import { useRef, useState } from "react";
import OtpInput from "react-otp-input";

interface formValues {
    otp: string;
}
interface Props {
    onSubmit: VerifyTwoFactorCallback;
    buttonText: string;
}

export type VerifyTwoFactorCallback = (
    otp: string,
    markSuccessful: () => Promise<void>,
) => Promise<void>;

export default function VerifyTwoFactor(props: Props) {
    const [waiting, setWaiting] = useState(false);
    const otpInputRef = useRef<OtpInput>(null);
    const [success, setSuccess] = useState(false);

    const markSuccessful = async () => {
        setWaiting(false);
        setSuccess(true);
        await wait(1000);
    };

    const submitForm = async (
        { otp }: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>,
    ) => {
        try {
            setWaiting(true);
            await props.onSubmit(otp, markSuccessful);
        } catch (e) {
            resetForm();
            for (let i = 0; i < 6; i++) {
                otpInputRef.current?.focusPrevInput();
            }
            const message = e instanceof Error ? e.message : "";
            setFieldError("otp", `${t("generic_error_retry")} ${message}`);
        }
        setWaiting(false);
    };

    const onChange =
        (callback: Function, triggerSubmit: Function) => (otp: string) => {
            callback(otp);
            if (otp.length === 6) {
                triggerSubmit(otp);
            }
        };
    return (
        <Formik<formValues>
            initialValues={{ otp: "" }}
            validateOnChange={false}
            validateOnBlur={false}
            onSubmit={submitForm}
        >
            {({ values, errors, handleChange, handleSubmit, submitForm }) => (
                <VerticallyCentered>
                    <form noValidate onSubmit={handleSubmit}>
                        <Typography mb={2} variant="small" color="text.muted">
                            {t("ENTER_TWO_FACTOR_OTP")}
                        </Typography>
                        <Box my={2}>
                            <OtpInput
                                ref={otpInputRef}
                                shouldAutoFocus
                                value={values.otp}
                                onChange={onChange(
                                    handleChange("otp"),
                                    submitForm,
                                )}
                                numInputs={6}
                                separator={"-"}
                                isInputNum
                                className={"otp-input"}
                            />
                            {errors.otp && (
                                <CenteredFlex sx={{ mt: 1 }}>
                                    <InvalidInputMessage>
                                        {t("INCORRECT_CODE")}
                                    </InvalidInputMessage>
                                </CenteredFlex>
                            )}
                        </Box>
                        <SubmitButton
                            buttonText={props.buttonText}
                            loading={waiting}
                            success={success}
                            disabled={values.otp.length < 6}
                        />
                    </form>
                </VerticallyCentered>
            )}
        </Formik>
    );
}
