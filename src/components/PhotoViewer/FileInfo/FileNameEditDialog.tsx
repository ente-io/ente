import React from 'react';
import constants from 'utils/strings/constants';
import { DialogContent, DialogTitle } from '@mui/material';
import DialogBoxBase from 'components/DialogBox/base';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';

export interface formValues {
    filename: string;
}

export const FileNameEditDialog = ({
    isInEditMode,
    closeEditMode,
    filename,
    extension,
    saveEdits,
}) => {
    const onSubmit: SingleInputFormProps['callback'] = async (
        filename,
        setFieldError
    ) => {
        try {
            await saveEdits(filename);
            closeEditMode();
        } catch (e) {
            setFieldError(constants.UNKNOWN_ERROR);
        }
    };
    return (
        <DialogBoxBase
            open={isInEditMode}
            onClose={closeEditMode}
            sx={{ zIndex: 1600 }}>
            <DialogTitle>{constants.RENAME_FILE}</DialogTitle>
            <DialogContent>
                <SingleInputForm
                    initialValue={filename}
                    callback={onSubmit}
                    placeholder={constants.ENTER_FILE_NAME}
                    buttonText={constants.RENAME}
                    fieldType="text"
                    caption={extension}
                    secondaryButtonAction={closeEditMode}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </DialogContent>
        </DialogBoxBase>
    );
};
