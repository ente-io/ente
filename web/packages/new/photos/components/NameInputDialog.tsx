import log from "@/base/log";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { Dialog, DialogContent, DialogTitle } from "@mui/material";
import { t } from "i18next";
import React from "react";
import { type DialogVisiblityProps } from "./mui/Dialog";

type NameInputDialogProps = DialogVisiblityProps & {
    /** Title of the dialog. */
    title: string;
    /** Placeholder string to show in the text input when it is empty. */
    placeholder: string;
    /** The existing value, if any, of the text input. */
    initialValue: string | undefined;
    /** Title of the submit button */
    submitButtonTitle: string;
    /**
     * Callback invoked when the submit button is pressed.
     *
     * @param name The current value of the text input.
     * */
    onSubmit: (name: string) => Promise<void>;
};

/**
 * A dialog that can be used to ask for a name or some other such singular text
 * input.
 *
 * See also: {@link CollectionNamer}, its older sibling.
 */
export const NameInputDialog: React.FC<NameInputDialogProps> = ({
    open,
    onClose,
    title,
    placeholder,
    initialValue,
    submitButtonTitle,
    onSubmit,
}) => {
    const handleSubmit: SingleInputFormProps["callback"] = async (
        inputValue,
        setFieldError,
    ) => {
        try {
            await onSubmit(inputValue);
            onClose();
        } catch (e) {
            log.error(`Error when submitting value ${inputValue}`, e);
            setFieldError(t("UNKNOWN_ERROR"));
        }
    };

    return (
        <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
            <DialogTitle>{title}</DialogTitle>
            <DialogContent>
                <SingleInputForm
                    fieldType="text"
                    placeholder={placeholder}
                    initialValue={initialValue}
                    callback={handleSubmit}
                    buttonText={submitButtonTitle}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                    secondaryButtonAction={onClose}
                />
            </DialogContent>
        </Dialog>
    );
};
