import React from 'react';
import DialogBox from './DialogBox';
import AutoAwesomeOutlinedIcon from '@mui/icons-material/AutoAwesomeOutlined';
import { Typography } from '@mui/material';
import SingleInputForm from './SingleInputForm';
import { t } from 'i18next';

export default function UserNameInputDialog({
    open,
    onClose,
    onNameSubmit,
    toUploadFilesCount,
    uploaderName,
}) {
    const handleSubmit = async (inputValue: string) => {
        onClose();
        await onNameSubmit(inputValue);
    };
    return (
        <DialogBox
            size="xs"
            open={open}
            onClose={onClose}
            attributes={{
                title: t('ENTER_NAME'),
                icon: <AutoAwesomeOutlinedIcon />,
            }}>
            <Typography color={'text.muted'} pb={1}>
                {t('PUBLIC_UPLOADER_NAME_MESSAGE')}
            </Typography>
            <SingleInputForm
                hiddenLabel
                initialValue={uploaderName}
                callback={handleSubmit}
                placeholder={t('NAME_PLACEHOLDER')}
                buttonText={t('add_photos', { count: toUploadFilesCount ?? 0 })}
                fieldType="text"
                blockButton
                secondaryButtonAction={onClose}
            />
        </DialogBox>
    );
}
