import ArrowForward from "@mui/icons-material/ArrowForward";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    Typography,
    styled,
    useMediaQuery,
} from "@mui/material";
import Slide from "@mui/material/Slide";
import type { TransitionProps } from "@mui/material/transitions";
import React, { useEffect } from "react";
import { didShowWhatsNew } from "../services/changelog";

interface WhatsNewProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Callback to invoke when the dialog wants to be closed. */
    onClose: () => void;
}

/**
 * Show a dialog showing a short summary of interesting-for-the-user things
 * since the last time this dialog was shown.
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

const SlideTransition = React.forwardRef(function Transition(
    props: TransitionProps & {
        children: React.ReactElement;
    },
    ref: React.Ref<unknown>,
) {
    return <Slide direction="up" ref={ref} {...props} />;
});

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
