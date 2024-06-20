import ArrowForward from "@mui/icons-material/ArrowForward";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    Typography,
    styled,
    useMediaQuery,
} from "@mui/material";
import React, { useEffect } from "react";
import { didShowWhatsNew } from "../services/changelog";
import { FocusVisibleButton } from "./FocusVisibleButton";
import { SlideTransition } from "./SlideTransition";

interface WhatsNewProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Called when the dialog wants to be closed. */
    onClose: () => void;
}

/**
 * A dialog showing a short summary of interesting-for-the-user things since the
 * last time this dialog was shown.
 */
export const WhatsNew: React.FC<WhatsNewProps> = ({ open, onClose }) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    useEffect(() => {
        if (open) void didShowWhatsNew();
    }, [open]);

    return (
        <Dialog
            {...{ open, fullScreen }}
            TransitionComponent={SlideTransition}
            maxWidth="xs"
        >
            <DialogTitle>{"What's new"}</DialogTitle>
            <DialogContent>
                <DialogContentText>
                    <ChangelogContent />
                </DialogContentText>
            </DialogContent>
            <DialogActions>
                <FocusVisibleButton
                    onClick={onClose}
                    color="accent"
                    fullWidth
                    disableRipple
                    endIcon={<ArrowForward />}
                >
                    <ButtonContents>{"Continue"}</ButtonContents>
                </FocusVisibleButton>
            </DialogActions>
        </Dialog>
    );
};

const ChangelogContent: React.FC = () => {
    // NOTE: Remember to update changelogVersion when changing the content
    // below.

    return (
        <StyledUL>
            <li>
                <Typography>
                    <Typography color="primary">
                        Support for Passkeys
                    </Typography>
                    Passkeys can now be used as a second factor authentication
                    mechanism.
                </Typography>
            </li>
            <li>
                <Typography color="primary">Window size</Typography>
                <Typography>
                    {"The app's window will remember its size and position."}
                </Typography>
            </li>
        </StyledUL>
    );
};

const StyledUL = styled("ul")`
    padding-inline: 1rem;

    li {
        margin-block: 2rem;
    }
`;

const ButtonContents = styled("div")`
    /* Make the button text fill the entire space so the endIcon shows at the
       trailing edge of the button. */
    width: 100%;
    text-align: left;
`;
