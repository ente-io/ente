import React from 'react';
import constants from 'utils/strings/constants';
import MessageDialogBase from 'components/MessageDialog/MessageDialogBase';
import { Box, Button, DialogContent } from '@mui/material';
import DialogTitleWithCloseButton from 'components/MessageDialog/TitleWithCloseButton';
import { FlexWrapper } from 'components/Container';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import { default as FileUploadIcon } from '@mui/icons-material/ImageOutlined';
import { default as FolderUploadIcon } from '@mui/icons-material/PermMediaOutlined';
import GoogleIcon from '@mui/icons-material/Google';

function UploadTypeRow({ uploadFunc, Icon, uploadName }) {
    return (
        <Button
            onClick={uploadFunc}
            variant="contained"
            fullWidth
            sx={{ mb: 2 }}>
            <FlexWrapper>
                <Icon sx={{ mr: 2 }} />
                <Box flex="1" textAlign={'left'}>
                    {uploadName}
                </Box>
                <NavigateNextIcon />
            </FlexWrapper>
        </Button>
    );
}

export default function UploadTypeSelector({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
}) {
    return (
        <MessageDialogBase open={show} maxWidth={'xs'} fullWidth>
            <DialogTitleWithCloseButton onClose={onHide}>
                {constants.UPLOAD}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ '&&&': { pt: 4 } }}>
                <UploadTypeRow
                    uploadFunc={uploadFiles}
                    Icon={FileUploadIcon}
                    uploadName={constants.UPLOAD_FILES}
                />

                <UploadTypeRow
                    uploadFunc={uploadFolders}
                    Icon={FolderUploadIcon}
                    uploadName={constants.UPLOAD_DIRS}
                />
                <UploadTypeRow
                    uploadFunc={uploadGoogleTakeoutZips}
                    Icon={GoogleIcon}
                    uploadName={constants.UPLOAD_GOOGLE_TAKEOUT}
                />
            </DialogContent>
        </MessageDialogBase>
    );
}
