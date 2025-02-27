import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { Dialog, DialogContent, DialogTitle } from "@mui/material";
import React from "react";
import { SingleInputForm, type SingleInputFormProps } from "./SingleInputForm";

type SingleInputDialogProps = ModalVisibilityProps &
    Omit<SingleInputFormProps, "onCancel"> & {
        /** Title of the dialog. */
        title: string;
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
    ...rest
}) => {
    const handleSubmit = async (value: string) => {
        await onSubmit(value);
        onClose();
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth="xs"
            fullWidth
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
