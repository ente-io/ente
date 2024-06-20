import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    TextField,
    useMediaQuery,
    type ModalProps,
} from "@mui/material";
import { useFormik } from "formik";
import React from "react";
import { FocusVisibleButton } from "./FocusVisibleButton";
import { SlideTransition } from "./SlideTransition";

interface DevSettingsProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Called when the dialog wants to be closed. */
    onClose: () => void;
}

/**
 * A dialog allowing the user to set the API origin that the app connects to.
 * See: [Note: Configuring custom server].
 */
export const DevSettings: React.FC<DevSettingsProps> = ({ open, onClose }) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    const handleDialogClose: ModalProps["onClose"] = (_, reason: string) => {
        // Don't close on backdrop clicks.
        if (reason != "backdropClick") onClose();
    };

    const form = useFormik({
        initialValues: { apiOrigin: "" },
        onSubmit: (values, { setSubmitting, setErrors }) => {
            setTimeout(() => {
                alert(JSON.stringify(values));
                if (values.apiOrigin.startsWith("test")) {
                    setErrors({ apiOrigin: "Testing indeed" });
                }
                setSubmitting(false);
            }, 400);
        },
    });

    return (
        <Dialog
            {...{ open, fullScreen }}
            onClose={handleDialogClose}
            TransitionComponent={SlideTransition}
            maxWidth="xs"
        >
            <form onSubmit={form.handleSubmit}>
                <DialogTitle>{"Developer settings"}</DialogTitle>
                <DialogContent>
                    <DialogContentText>
                        <TextField
                            fullWidth
                            id="apiOrigin"
                            name="apiOrigin"
                            label="Server endpoint"
                            placeholder="http://localhost:8080"
                            value={form.values.apiOrigin}
                            onChange={form.handleChange}
                            onBlur={form.handleBlur}
                            error={
                                form.touched.apiOrigin &&
                                !!form.errors.apiOrigin
                            }
                            helperText={
                                form.touched.apiOrigin && form.errors.apiOrigin
                            }
                        />
                    </DialogContentText>
                </DialogContent>
                <DialogActions>
                    <FocusVisibleButton
                        type="submit"
                        color="accent"
                        fullWidth
                        disabled={form.isSubmitting}
                        disableRipple
                    >
                        {"Save"}
                    </FocusVisibleButton>
                    <FocusVisibleButton
                        onClick={onClose}
                        color="secondary"
                        fullWidth
                        disableRipple
                    >
                        {"Cancel"}
                    </FocusVisibleButton>
                </DialogActions>
            </form>
        </Dialog>
    );
};
