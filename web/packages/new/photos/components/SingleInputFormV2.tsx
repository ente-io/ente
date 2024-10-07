import { Dialog, DialogContent, DialogTitle, TextField } from "@mui/material";
import React from "react";
import type { DialogVisibilityProps } from "./mui/Dialog";

/**
 * A TextField and two buttons.
 */
export const SingleInputFormV2: React.FC = () => {
    return (
        <div>
            <TextField></TextField>
        </div>
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
            <DialogTitle>{"Title"}</DialogTitle>
            <DialogContent>
                <SingleInputFormV2 />
            </DialogContent>
        </Dialog>
    );
};
