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
        <Dialog open={true} fullScreen={fullScreen} maxWidth="xs">
            <DialogTitle>{"What's new"}</DialogTitle>
            <DialogContent>
                <DialogContentText>
                    <StyledUL>
                        <li>
                            The app will remember its position and size when it
                            is closed, and will reopen the same way.
                        </li>
                    </StyledUL>
                </DialogContentText>
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

const StyledUL = styled("ul")`
    padding-inline: 1rem;
    list-style-type: circle;
`;

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
