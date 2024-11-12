import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import { DialogTitle, IconButton, Typography } from "@mui/material";
import React from "react";

interface DialogTitleWithCloseButtonProps {
    onClose: () => void;
}

const DialogTitleWithCloseButton: React.FC<
    React.PropsWithChildren<DialogTitleWithCloseButtonProps>
> = ({ children, onClose }) => {
    return (
        <DialogTitle>
            <SpaceBetweenFlex>
                <Typography variant="h3" fontWeight={"bold"}>
                    {children}
                </Typography>
                {onClose && (
                    <IconButton
                        aria-label="close"
                        onClick={onClose}
                        sx={{ float: "right" }}
                        color="secondary"
                    >
                        <CloseIcon />
                    </IconButton>
                )}
            </SpaceBetweenFlex>
        </DialogTitle>
    );
};
export default DialogTitleWithCloseButton;
