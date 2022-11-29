import React from 'react';
import constants from 'utils/strings/constants';
import { default as FileUploadIcon } from '@mui/icons-material/ImageOutlined';
import { default as FolderUploadIcon } from '@mui/icons-material/PermMediaOutlined';
import GoogleIcon from '@mui/icons-material/Google';
import { UploadTypeOption } from './option';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';
import { Box, Dialog, Stack, Typography } from '@mui/material';

interface Iprops {
    onHide: () => void;
    show: boolean;
    uploadFiles: () => void;
    uploadFolders: () => void;
    uploadGoogleTakeoutZips: () => void;
    hideZipUploadOption?: boolean;
}
export default function UploadTypeSelector({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
    hideZipUploadOption,
}: Iprops) {
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
                        onClick={uploadFiles}
                        startIcon={<FileUploadIcon />}>
                        {constants.UPLOAD_FILES}
                    </UploadTypeOption>
                    <UploadTypeOption
                        onClick={uploadFolders}
                        startIcon={<FolderUploadIcon />}>
                        {constants.UPLOAD_DIRS}
                    </UploadTypeOption>
                    {!hideZipUploadOption && (
                        <UploadTypeOption
                            onClick={uploadGoogleTakeoutZips}
                            startIcon={<GoogleIcon />}>
                            {constants.UPLOAD_GOOGLE_TAKEOUT}
                        </UploadTypeOption>
                    )}
                </Stack>
                <Typography p={1.5} pt={4} color="text.secondary">
                    {constants.DRAG_AND_DROP_HINT}
                </Typography>
            </Box>
        </Dialog>
    );
}
