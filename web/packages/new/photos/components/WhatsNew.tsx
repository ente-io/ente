import ArrowForward from "@mui/icons-material/ArrowForward";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    styled,
    useMediaQuery,
} from "@mui/material";
import React from "react";

interface WhatsNewProps {
    /** Invoked by the component when it wants to get closed. */
    onClose: () => void;
}

/**
 * Show a dialog showing a short summary of interesting-for-the-user things in
 * this release of the desktop app.
 */
export const WhatsNew: React.FC<WhatsNewProps> = ({ onClose }) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    return (
        <Dialog open={true} fullScreen={fullScreen}>
            <DialogTitle>{"What's new"}</DialogTitle>
            <DialogContent>
                <DialogContentText>Content</DialogContentText>
            </DialogContent>
            <DialogActions>
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
        </Dialog>
    );
};

const ButtonContents = styled("div")`
    width: 100%;
    text-align: left;
`;

const StyledButton = styled(Button)`
    &.Mui-focusVisible {
        outline: 1px solid #aaa;
    }
`;
