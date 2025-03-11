import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import { FlexWrapper } from "@ente/shared/components/Container";
import ShowHidePassword from "@ente/shared/components/Form/ShowHidePassword";
import { FormHelperText } from "@mui/material";
import TextField from "@mui/material/TextField";
import { Formik, type FormikHelpers, type FormikState } from "formik";
import { t } from "i18next";
import React, { useMemo, useState } from "react";
import * as Yup from "yup";

interface formValues {
    inputValue: string;
}
export interface SingleInputFormProps {
    callback: (
        inputValue: string,
        setFieldError: (errorMessage: string) => void,
        resetForm: (nextState?: Partial<FormikState<formValues>>) => void,
    ) => Promise<void>;
    fieldType: "text" | "email" | "password";
    /** deprecated: Use realPlaceholder */
    placeholder?: string;
    /**
     * Placeholder
     *
     * The existing `placeholder` property uses the placeholder as a label (i.e.
     * it doesn't appear as the placeholder within the text input area but
     * rather as the label on top of it). This happens conditionally, so it is
     * not a matter of simple rename.
     *
     * Gradually migrate the existing UI to use this property when we really
     * want a placeholder, and then create a separate label property for places
     * that actually want to set the label.
     */
    realPlaceholder?: string;
    /**
     * Label to show on top of the text input area.
     *
     * Sibling of {@link realPlaceholder}.
     */
    realLabel?: string;
    buttonText: string;
    submitButtonProps?: any;
    initialValue?: string;
    secondaryButtonAction?: () => void;
    disableAutoFocus?: boolean;
    hiddenPreInput?: any;
    caption?: any;
    hiddenPostInput?: any;
    autoComplete?: string;
    blockButton?: boolean;
    hiddenLabel?: boolean;
    disableAutoComplete?: boolean;
}

/**
 * Deprecated version, gradually migrate to use the one from @/base.
 */
export default function SingleInputForm(props: SingleInputFormProps) {
    const { submitButtonProps } = props;
    const { sx: buttonSx, ...restSubmitButtonProps } = submitButtonProps ?? {};

    const [loading, SetLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const submitForm = async (
        values: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>,
    ) => {
        SetLoading(true);
        await props.callback(
            values.inputValue,
            (message) => setFieldError("inputValue", message),
            resetForm,
        );
        SetLoading(false);
    };

    const handleClickShowPassword = () => {
        setShowPassword(!showPassword);
    };

    const handleMouseDownPassword = (
        event: React.MouseEvent<HTMLButtonElement>,
    ) => {
        event.preventDefault();
    };

    const validationSchema = useMemo(() => {
        switch (props.fieldType) {
            case "text":
                return Yup.object().shape({
                    inputValue: Yup.string().required(t("required")),
                });
            case "password":
                return Yup.object().shape({
                    inputValue: Yup.string().required(t("required")),
                });
            case "email":
                return Yup.object().shape({
                    inputValue: Yup.string()
                        .email(t("invalid_email_error"))
                        .required(t("required")),
                });
        }
    }, [props.fieldType]);

    return (
        <Formik<formValues>
            initialValues={{ inputValue: props.initialValue ?? "" }}
            onSubmit={submitForm}
            validationSchema={validationSchema}
            validateOnChange={false}
            validateOnBlur={false}
        >
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit}>
                    {props.hiddenPreInput}
                    <TextField
                        hiddenLabel={props.hiddenLabel}
                        variant="filled"
                        fullWidth
                        type={showPassword ? "text" : props.fieldType}
                        id={props.fieldType}
                        name={props.fieldType}
                        {...(props.hiddenLabel
                            ? { placeholder: props.placeholder }
                            : props.realPlaceholder
                              ? {
                                    placeholder: props.realPlaceholder,
                                    label: props.realLabel,
                                }
                              : { label: props.placeholder })}
                        value={values.inputValue}
                        onChange={handleChange("inputValue")}
                        error={Boolean(errors.inputValue)}
                        helperText={errors.inputValue}
                        disabled={loading}
                        autoFocus={!props.disableAutoFocus}
                        autoComplete={props.autoComplete}
                        slotProps={{
                            input: {
                                autoComplete:
                                    props.disableAutoComplete ||
                                    props.fieldType === "password"
                                        ? "off"
                                        : "on",
                                endAdornment: props.fieldType ===
                                    "password" && (
                                    <ShowHidePassword
                                        showPassword={showPassword}
                                        handleClickShowPassword={
                                            handleClickShowPassword
                                        }
                                        handleMouseDownPassword={
                                            handleMouseDownPassword
                                        }
                                    />
                                ),
                            },
                        }}
                    />
                    <FormHelperText
                        sx={{
                            position: "relative",
                            top: errors.inputValue ? "-22px" : "0",
                            float: "right",
                            padding: "0 8px",
                        }}
                    >
                        {props.caption}
                    </FormHelperText>
                    {props.hiddenPostInput}
                    <FlexWrapper
                        justifyContent={"flex-end"}
                        flexWrap={props.blockButton ? "wrap-reverse" : "nowrap"}
                    >
                        {props.secondaryButtonAction && (
                            <FocusVisibleButton
                                onClick={props.secondaryButtonAction}
                                fullWidth
                                color="secondary"
                                sx={{
                                    "&&&": {
                                        mt: !props.blockButton ? 2 : 0.5,
                                        mb: !props.blockButton ? 4 : 0,
                                        mr: !props.blockButton ? 1 : 0,
                                        ...buttonSx,
                                    },
                                }}
                                {...restSubmitButtonProps}
                            >
                                {t("cancel")}
                            </FocusVisibleButton>
                        )}
                        <LoadingButton
                            sx={{ "&&&": { mt: 2, ...buttonSx } }}
                            fullWidth
                            variant="contained"
                            color="accent"
                            type="submit"
                            loading={loading}
                            {...restSubmitButtonProps}
                        >
                            {props.buttonText}
                        </LoadingButton>
                    </FlexWrapper>
                </form>
            )}
        </Formik>
    );
}
