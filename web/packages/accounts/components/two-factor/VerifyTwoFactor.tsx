import { LoadingButton } from "@/base/components/mui/LoadingButton";
import {
    CenteredFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import { Box, Typography, styled } from "@mui/material";
import { Formik, type FormikHelpers } from "formik";
import { t } from "i18next";
import React, { useState } from "react";
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
    markSuccessful: () => void,
) => Promise<void>;

export function VerifyTwoFactor(props: Props) {
    const [waiting, setWaiting] = useState(false);
    const [shouldAutoFocus, setShouldAutoFocus] = useState(true);

    const markSuccessful = () => setWaiting(false);

    const submitForm = async (
        { otp }: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>,
    ) => {
        try {
            setWaiting(true);
            await props.onSubmit(otp, markSuccessful);
        } catch (e) {
            resetForm();
            const message = e instanceof Error ? e.message : "";
            setFieldError("otp", `${t("generic_error_retry")} ${message}`);
            // Workaround (toggling shouldAutoFocus) to reset the focus back to
            // the first input field in case of errors.
            // https://github.com/devfolioco/react-otp-input/issues/420
            setShouldAutoFocus(false);
            setTimeout(() => setShouldAutoFocus(true), 100);
        }
        setWaiting(false);
    };

    const onChange =
        // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
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
                        <Typography
                            variant="small"
                            sx={{ mb: 2, color: "text.muted" }}
                        >
                            {t("enter_two_factor_otp")}
                        </Typography>
                        <Box sx={{ my: 2 }}>
                            <OtpInput
                                containerStyle={{ justifyContent: "center" }}
                                shouldAutoFocus={shouldAutoFocus}
                                value={values.otp}
                                onChange={onChange(
                                    handleChange("otp"),
                                    submitForm,
                                )}
                                numInputs={6}
                                renderSeparator={<span>-</span>}
                                renderInput={(props) => (
                                    <IndividualInput {...props} />
                                )}
                            />
                            {errors.otp && (
                                <CenteredFlex sx={{ mt: 1 }}>
                                    <InvalidInputMessage>
                                        {t("incorrect_code")}
                                    </InvalidInputMessage>
                                </CenteredFlex>
                            )}
                        </Box>
                        <LoadingButton
                            type="submit"
                            color="accent"
                            fullWidth
                            sx={{ my: 4 }}
                            loading={waiting}
                            disabled={values.otp.length < 6}
                        >
                            {props.buttonText}
                        </LoadingButton>
                    </form>
                </VerticallyCentered>
            )}
        </Formik>
    );
}

const IndividualInput = styled("input")(
    ({ theme }) => `
    font-size: 1.5rem;
    padding: 4px;
    width: 40px !important;
    aspect-ratio: 1;
    margin-inline: 6px;
    border: 1px solid ${theme.vars.palette.accent.main};
    border-radius: 1px;
    outline-color: ${theme.vars.palette.accent.light};
    transition: 0.5s;
    ${theme.breakpoints.down("sm")} {
        font-size: 1rem;
        padding: 4px;
        width: 32px !important;
    }
`,
);

const InvalidInputMessage: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <Typography variant="mini" sx={{ color: "critical.main" }}>
        {children}
    </Typography>
);
