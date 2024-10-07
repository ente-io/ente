import { wait } from "@/utils/promise";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    TextField,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";
import { FocusVisibleButton } from "./FocusVisibleButton";
import type { DialogVisibilityProps } from "./mui/Dialog";
import log from "@/base/log";

/**
 * A TextField and two buttons.
 */
export const SingleInputFormV2: React.FC = () => {
    const formik = useFormik({
        initialValues: {
            name: "",
        },
        onSubmit: async (values, { setFieldError }) => {
            const name = values.name;
            if (!name) {
                setFieldError("name", t("required"));
                return;
            }
            try {
                await wait(1000);
                if (values.name == "t") throw new Error("test");
            } catch (e) {
                log.error(`Failed to submit input ${name}`, e)
                setFieldError("name", t("UNKNOWN_ERROR"))
            }
            console.log(JSON.stringify(values));
        },
    });

    // Note: [Use space as default TextField helperText]
    //
    // For MUI text fields that use a conditional helperText, e.g. in case of
    // errors, use an space as the default helperText in the other cases to
    // avoid a layout shift when the helperText is conditionally shown.

    return (
        <form onSubmit={formik.handleSubmit}>
            <TextField
                name="name"
                value={formik.values.name}
                onChange={formik.handleChange}
                type="text"
                autoComplete="name"
                autoFocus
                fullWidth
                label="Add name"
                margin="normal"
                placeholder="Enter name"
                error={!!formik.errors.name}
                helperText={formik.errors.name ?? " "}
            />
            <Box sx={{ display: "flex", gap: "12px" }}>
                <FocusVisibleButton size="large" color="secondary">
                    {t("cancel")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    size="large"
                    color="accent"
                    type="submit"
                    disabled={formik.isSubmitting}
                >
                    Add person
                </FocusVisibleButton>
            </Box>
        </form>
    );
};

export const SingleInputDialogTest: React.FC<DialogVisibilityProps> = ({
    open,
    onClose,
}) => {
    // const handleSubmit: SingleInputFormProps["callback"] = async (
    //     inputValue,
    //     setFieldError,
    // ) => {
    //     try {
    //         await onSubmit(inputValue);
    //         onClose();
    //     } catch (e) {
    //         log.error(`Error when submitting value ${inputValue}`, e);
    //         setFieldError(t("UNKNOWN_ERROR"));
    //     }
    // };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullWidth
            PaperProps={{ sx: { padding: "8px 4px 4px 4px" } }}
        >
            <DialogTitle>{"New person"}</DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: 0 } }}>
                <SingleInputFormV2 />
            </DialogContent>
        </Dialog>
    );
};
