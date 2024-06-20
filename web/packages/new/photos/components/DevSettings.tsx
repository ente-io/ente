import ArrowForward from "@mui/icons-material/ArrowForward";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    styled,
    TextField,
    useMediaQuery,
    type ModalProps,
} from "@mui/material";
import { useFormik } from "formik";
import React from "react";
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

    const formik = useFormik({
        initialValues: { apiOrigin: "" },
        onSubmit: (values, { setSubmitting }) => {
            setTimeout(() => {
                alert(JSON.stringify(values));
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
            <form onSubmit={formik.handleSubmit}>
                <DialogTitle>{"Developer settings"}</DialogTitle>
                <DialogContent>
                    <DialogContentText>
                        <TextField
                            fullWidth
                            id="apiOrigin"
                            name="apiOrigin"
                            label="Server endpoint"
                            value={formik.values.apiOrigin}
                            onChange={formik.handleChange}
                            onBlur={formik.handleBlur}
                            error={
                                formik.touched.apiOrigin &&
                                !!formik.errors.apiOrigin
                            }
                        />
                    </DialogContentText>
                </DialogContent>
                <DialogActions>
                    <StyledButton
                        type="submit"
                        color="accent"
                        fullWidth
                        disabled={formik.isSubmitting}
                        disableRipple
                        endIcon={<ArrowForward />}
                    >
                        <ButtonContents>{"Save"}</ButtonContents>
                    </StyledButton>
                    <StyledButton
                        onClick={onClose}
                        color="accent"
                        fullWidth
                        disableRipple
                        endIcon={<ArrowForward />}
                    >
                        <ButtonContents>{"Continue"}</ButtonContents>
                    </StyledButton>
                </DialogActions>
            </form>
        </Dialog>
    );
};

const StyledButton = styled(Button)`
    /* Show an outline when the button gains keyboard focus, e.g. when the user
       tabs to it. */
    &.Mui-focusVisible {
        outline: 1px solid #aaa;
    }
`;

const ButtonContents = styled("div")`
    /* Make the button text fill the entire space so the endIcon shows at the
       trailing edge of the button. */
    width: 100%;
    text-align: left;
`;
