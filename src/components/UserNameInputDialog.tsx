import React from 'react';
import constants from 'utils/strings/constants';
import DialogBox from './DialogBox';
import AutoAwesomeOutlinedIcon from '@mui/icons-material/AutoAwesomeOutlined';
import { Typography } from '@mui/material';
import SingleInputForm from './SingleInputForm';

export default function UserNameInputDialog({ open, onClose, onNameSubmit }) {
    const handleSubmit = async (inputValue: string) => {
        onClose();
        await onNameSubmit(inputValue);
    };
    return (
        <DialogBox
            sx={{ zIndex: 1600 }}
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
                callback={handleSubmit}
                placeholder={constants.ENTER_FILE_NAME}
                buttonText={constants.CONTINUE}
                fieldType="text"
                blockButton
                secondaryButtonAction={() => {}}
            />
        </DialogBox>
    );
}
