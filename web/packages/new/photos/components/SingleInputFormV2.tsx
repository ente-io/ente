import {
    Box,
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    TextField,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";
import type { DialogVisibilityProps } from "./mui/Dialog";

/**
 * A TextField and two buttons.
 */
export const SingleInputFormV2: React.FC = () => {
    const formik = useFormik({
        initialValues: {
            name: "",
        },
        onSubmit: (values) => {
            console.log(JSON.stringify(values));
        },
    });
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
                placeholder="Enter name"
                helperText=" "
            />
            <Box sx={{ display: "flex", paddingInline: "4px", gap: "12px" }}>
                <Button size="large" color="secondary">
                    {t("cancel")}
                </Button>
                <Button size="large" color="accent" type="submit">
                    Add person
                </Button>
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
            <DialogContent>
                <SingleInputFormV2 />
            </DialogContent>
        </Dialog>
    );
};
