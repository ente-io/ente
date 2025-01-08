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
 * If the submission handler provided to this component resolves successfully,
 * then the dialog is closed.
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
            PaperProps={{ sx: { padding: "8px 4px 4px 4px" } }}
        >
            <DialogTitle>{title}</DialogTitle>
            <DialogContent sx={{ "&&&": { paddingBlockStart: 0 } }}>
                <SingleInputForm
                    onCancel={onClose}
                    onSubmit={handleSubmit}
                    {...rest}
                />
            </DialogContent>
        </Dialog>
    );
};
