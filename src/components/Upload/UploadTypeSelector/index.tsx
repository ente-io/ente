import React, { useContext, useEffect, useRef } from 'react';
import { t } from 'i18next';

import { default as FileUploadIcon } from '@mui/icons-material/ImageOutlined';
import { default as FolderUploadIcon } from '@mui/icons-material/PermMediaOutlined';
import GoogleIcon from '@mui/icons-material/Google';
import { UploadTypeOption } from './option';
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from 'components/DialogBox/TitleWithCloseButton';
import { Box, Dialog, Stack, Typography } from '@mui/material';
import { PublicCollectionGalleryContext } from 'utils/publicCollectionGallery';
import { isMobileOrTable } from 'utils/common/deviceDetection';
import { UploadTypeSelectorIntent } from 'types/gallery';
interface Iprops {
    onClose: () => void;
    show: boolean;
    uploadFiles: () => void;
    uploadFolders: () => void;
    uploadGoogleTakeoutZips: () => void;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
}
export default function UploadTypeSelector({
    onClose,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
    uploadTypeSelectorIntent,
}: Iprops) {
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext
    );
    const directlyShowUploadFiles = useRef(isMobileOrTable());

    useEffect(() => {
        if (
            show &&
            directlyShowUploadFiles.current &&
            publicCollectionGalleryContext.accessedThroughSharedURL
        ) {
            uploadFiles();
            onClose();
        }
    }, [show]);

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
            onClose={dialogCloseHandler({ onClose })}>
            <DialogTitleWithCloseButton onClose={onClose}>
                {uploadTypeSelectorIntent ===
                UploadTypeSelectorIntent.collectPhotos
                    ? t('SELECT_PHOTOS')
                    : uploadTypeSelectorIntent ===
                      UploadTypeSelectorIntent.import
                    ? t('IMPORT')
                    : t('UPLOAD')}
            </DialogTitleWithCloseButton>
            <Box p={1.5} pt={0.5}>
                <Stack spacing={0.5}>
                    {uploadTypeSelectorIntent !==
                        UploadTypeSelectorIntent.import && (
                        <UploadTypeOption
                            onClick={uploadFiles}
                            startIcon={<FileUploadIcon />}>
                            {t('UPLOAD_FILES')}
                        </UploadTypeOption>
                    )}
                    <UploadTypeOption
                        onClick={uploadFolders}
                        startIcon={<FolderUploadIcon />}>
                        {t('UPLOAD_DIRS')}
                    </UploadTypeOption>
                    {uploadTypeSelectorIntent !==
                        UploadTypeSelectorIntent.collectPhotos && (
                        <UploadTypeOption
                            onClick={uploadGoogleTakeoutZips}
                            startIcon={<GoogleIcon />}>
                            {t('UPLOAD_GOOGLE_TAKEOUT')}
                        </UploadTypeOption>
                    )}
                </Stack>
                <Typography p={1.5} pt={4} color="text.muted">
                    {t('DRAG_AND_DROP_HINT')}
                </Typography>
            </Box>
        </Dialog>
    );
}
