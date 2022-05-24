import React from 'react';
import constants from 'utils/strings/constants';
import { default as FileUploadIcon } from '@mui/icons-material/ImageOutlined';
import { default as FolderUploadIcon } from '@mui/icons-material/PermMediaOutlined';
import GoogleIcon from '@mui/icons-material/Google';
import DialogBox from 'components/DialogBox';
import { UploadTypeOption } from './option';

export default function UploadTypeSelector({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
}) {
    return (
        <DialogBox
            attributes={{
                title: constants.UPLOAD,
            }}
            open={show}
            size={'xs'}
            onClose={onHide}
            titleCloseButton>
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
        </DialogBox>
    );
}
