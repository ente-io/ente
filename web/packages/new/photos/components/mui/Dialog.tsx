import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import CloseIcon from "@mui/icons-material/Close";
import { IconButton } from "@mui/material";
import { t } from "i18next";
import React from "react";

type DialogCloseIconButtonProps = Omit<ModalVisibilityProps, "open">;

/**
 * A convenience {@link IconButton} commonly needed on {@link Dialog}s, at the
 * top right, to allow the user to close the dialog.
 *
 * Note that an explicit "Cancel" button is a better approach whenever possible,
 * so use this sparingly.
 */
export const DialogCloseIconButton: React.FC<DialogCloseIconButtonProps> = ({
    onClose,
}) => (
    <IconButton aria-label={t("close")} color="secondary" onClick={onClose}>
        <CloseIcon />
    </IconButton>
);
