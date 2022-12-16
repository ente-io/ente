import React from 'react';
import constants from 'utils/strings/constants';
import DialogBox from './DialogBox';
import AutoAwesomeOutlinedIcon from '@mui/icons-material/AutoAwesomeOutlined';
import { Typography } from '@mui/material';
import SingleInputForm from './SingleInputForm';

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
                title: constants.ENTER_NAME,
                icon: <AutoAwesomeOutlinedIcon />,
            }}>
            <Typography color={'text.secondary'} pb={1}>
                {constants.PUBLIC_UPLOADER_NAME_MESSAGE}
            </Typography>
            <SingleInputForm
                initialValue={uploaderName}
                callback={handleSubmit}
                placeholder={constants.ENTER_FILE_NAME}
                buttonText={constants.ADD_X_PHOTOS(toUploadFilesCount)}
                fieldType="text"
                blockButton
                secondaryButtonAction={onClose}
            />
        </DialogBox>
    );
}
