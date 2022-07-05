import React from 'react';
import constants from 'utils/strings/constants';
import { default as FileUploadIcon } from '@mui/icons-material/ImageOutlined';
import { default as FolderUploadIcon } from '@mui/icons-material/PermMediaOutlined';
import GoogleIcon from '@mui/icons-material/Google';
import { UploadTypeOption } from './option';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { Box, Dialog, Stack, Typography } from '@mui/material';

export default function UploadTypeSelector({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
}) {
    return (
        <Dialog
            open={show}
            PaperProps={{
                sx: (theme) => ({
                    maxWidth: '375px',
                    p: 1,
                    [theme.breakpoints.down(360)]: { p: 0 },
                }),
            }}
            onClose={onHide}>
            <DialogTitleWithCloseButton onClose={onHide}>
                {constants.UPLOAD}
            </DialogTitleWithCloseButton>
            <Box p={1.5} pt={0.5}>
                <Stack spacing={0.5}>
                    <UploadTypeOption
                        uploadFunc={uploadFiles}
                        Icon={FileUploadIcon}
                        uploadName={constants.UPLOAD_FILES}
                    />
                    <UploadTypeOption
                        uploadFunc={uploadFolders}
                        Icon={FolderUploadIcon}
                        uploadName={constants.UPLOAD_DIRS}
                    />
                    <UploadTypeOption
                        uploadFunc={uploadGoogleTakeoutZips}
                        Icon={GoogleIcon}
                        uploadName={constants.UPLOAD_GOOGLE_TAKEOUT}
                    />
                </Stack>
                <Typography p={1.5} pt={4} color="text.secondary">
                    {constants.DRAG_AND_DROP_HINT}
                </Typography>
            </Box>
        </Dialog>
    );
}
