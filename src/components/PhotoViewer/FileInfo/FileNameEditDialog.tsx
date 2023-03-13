import React from 'react';
import { DialogContent, DialogTitle } from '@mui/material';
import DialogBoxBase from 'components/DialogBox/base';
import SingleInputForm, {
    SingleInputFormProps,
} from 'components/SingleInputForm';
import { useTranslation } from 'react-i18next';

export const FileNameEditDialog = ({
    isInEditMode,
    closeEditMode,
    filename,
    extension,
    saveEdits,
}) => {
    const { t } = useTranslation();

    const onSubmit: SingleInputFormProps['callback'] = async (
        filename,
        setFieldError
    ) => {
        try {
            await saveEdits(filename);
            closeEditMode();
        } catch (e) {
            setFieldError(t('UNKNOWN_ERROR'));
        }
    };
    return (
        <DialogBoxBase
            open={isInEditMode}
            onClose={closeEditMode}
            sx={{ zIndex: 1600 }}>
            <DialogTitle>{t('RENAME_FILE')}</DialogTitle>
            <DialogContent>
                <SingleInputForm
                    initialValue={filename}
                    callback={onSubmit}
                    placeholder={t('ENTER_FILE_NAME')}
                    buttonText={t('RENAME')}
                    fieldType="text"
                    caption={extension}
                    secondaryButtonAction={closeEditMode}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </DialogContent>
        </DialogBoxBase>
    );
};
