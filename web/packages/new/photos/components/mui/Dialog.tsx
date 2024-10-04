import CloseIcon from "@mui/icons-material/Close";
import { DialogTitle, IconButton, styled, Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";

/**
 * A DialogTitle component that new code should use instead of the MUI
 * {@link DialogTitle} when possible.
 *
 * This reverts some of the global padding styleOverrides instead of disabling
 * them ad-hoc. The intent is that once enough of the existing dialogs have
 * moved to this component, these can be added as a variant in the MUI global
 * styleOverrides, and this component should not be needed them. We can also see
 * if a different variant pattern emerges once we start using this.
 *
 * The global styleOverrides in consideration:
 *
 *     "& .MuiDialogTitle-root": {
 *         padding: "16px",
 *     },
 *     "& .MuiDialogContent-root": {
 *         padding: "16px",
 *         overflowY: "overlay",
 *     },
 *     "& .MuiDialogActions-root": {
 *         padding: "16px",
 *     },
 *     ".MuiDialogTitle-root + .MuiDialogContent-root": {
 *         paddingTop: "16px",
 *     },
 *
 */
export const DialogTitleV3 = styled(DialogTitle)`
    "&&&": {
        padding: 0;
    }
`;

interface DialogTitleV3WithCloseButtonProps {
    onClose: () => void;
}

export const DialogTitleV3WithCloseButton: React.FC<
    React.PropsWithChildren<DialogTitleV3WithCloseButtonProps>
> = ({ onClose, children }) => (
    <DialogTitle
        sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            "&&&": { paddingBlockEnd: 0 },
        }}
    >
        <Typography variant="large" fontWeight={"bold"}>
            {children}
        </Typography>
        <IconButton
            aria-label={t("close")}
            color="secondary"
            onClick={onClose}
            sx={{ marginInlineEnd: "-12px" }}
        >
            <CloseIcon />
        </IconButton>
    </DialogTitle>
);
