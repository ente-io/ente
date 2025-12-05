import { Dialog, DialogContent, DialogTitle, useTheme } from "@mui/material";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import React, { useCallback } from "react";
import { SingleInputForm, type SingleInputFormProps } from "./SingleInputForm";

type SingleInputDialogProps = ModalVisibilityProps &
    Omit<SingleInputFormProps, "onCancel"> & {
        /** Title of the dialog. */
        title: string;
        /** Optional z-index override to layer above other dialogs. */
        zIndex?: number;
    };

/**
 * A dialog that can be used to ask for a single text input using a
 * {@link SingleInputForm}.
 *
 * The dialog closes when the promise returned by the {@link onSubmit} callback
 * fulfills.
 *
 * See also: {@link CollectionNamer}, its older sibling.
 */
export const SingleInputDialog: React.FC<SingleInputDialogProps> = ({
    open,
    onClose,
    onSubmit,
    title,
    zIndex,
    ...rest
}) => {
    const theme = useTheme();
    const dialogZIndex = zIndex ?? theme.zIndex.modal + 4;

    const handleSubmit: SingleInputFormProps["onSubmit"] = useCallback(
        async (value, setFieldError) => {
            await onSubmit(value, setFieldError);
            onClose();
        },
        [onClose, onSubmit],
    );

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullWidth
            sx={{ zIndex: dialogZIndex }}
            slotProps={{ paper: { sx: { p: "8px 4px 4px 4px" } } }}
        >
            <DialogTitle>{title}</DialogTitle>
            <DialogContent sx={{ "&&&": { pt: 0 } }}>
                <SingleInputForm
                    onCancel={onClose}
                    onSubmit={handleSubmit}
                    {...rest}
                />
            </DialogContent>
        </Dialog>
    );
};
