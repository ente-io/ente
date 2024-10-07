import { ensureElectron } from "@/base/electron";
import { useIsMobileWidth } from "@/base/hooks";
import { ut } from "@/base/i18n";
import ArrowForward from "@mui/icons-material/ArrowForward";
import {
    Box,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    Typography,
    styled,
} from "@mui/material";
import React, { useEffect } from "react";
import { didShowWhatsNew } from "../services/changelog";
import { FocusVisibleButton } from "./mui/FocusVisibleButton";
import { SlideUpTransition } from "./mui/SlideUpTransition";

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
    const fullScreen = useIsMobileWidth();

    useEffect(() => {
        if (open) void didShowWhatsNew(ensureElectron());
    }, [open]);

    return (
        <Dialog
            {...{ open, fullScreen }}
            TransitionComponent={SlideUpTransition}
            maxWidth="xs"
            fullWidth
        >
            <Box m={1}>
                <DialogTitle mt={2}>
                    <Typography variant="h4" color="text.muted">
                        {ut("What's new")}
                    </Typography>
                </DialogTitle>
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
                        endIcon={<ArrowForward />}
                    >
                        <ButtonContents>{ut("Continue")}</ButtonContents>
                    </FocusVisibleButton>
                </DialogActions>
            </Box>
        </Dialog>
    );
};

const ChangelogContent: React.FC = () => {
    // NOTE: Remember to update changelogVersion when changing the content
    // below.

    return (
        <StyledUL>
            <li>
                <Typography color="primary">
                    {ut("Improved date search")}
                </Typography>
                <Typography>
                    Search for photos by day of week (<i>Wednesday</i>) or hour
                    of day (<i>8 pm</i>) in addition to the existing search by
                    partial dates (<i>20 July</i>, or even <i>2021</i>) and
                    relative dates (<i>Last month</i>,<i>Yesterday</i>).
                </Typography>
            </li>
            <li>
                <Typography color="primary">
                    {ut("Faster magic search")}
                </Typography>
                <Typography>
                    {ut(
                        "The magic search beta, where you can search for photos just by typing whatever is in them, just got faster.",
                    )}
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
