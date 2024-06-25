import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import ChevronRight from "@mui/icons-material/ChevronRight";
import GoogleIcon from "@mui/icons-material/Google";
import { default as FileUploadIcon } from "@mui/icons-material/ImageOutlined";
import { default as FolderUploadIcon } from "@mui/icons-material/PermMediaOutlined";
import { Box, Dialog, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import React, { useContext, useEffect, useRef } from "react";
import { UploadTypeSelectorIntent } from "types/gallery";
import { isMobileOrTable } from "utils/common/deviceDetection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";

interface UploadTypeSelectorProps {
    onClose: () => void;
    show: boolean;
    uploadFiles: () => void;
    uploadFolders: () => void;
    uploadGoogleTakeoutZips: () => void;
    uploadTypeSelectorIntent: UploadTypeSelectorIntent;
}

/**
 * Request the user to specify which type of file / folder / zip it is that they
 * wish to upload.
 *
 * This selector (and the "Upload" button) is functionally redundant, the user
 * can just drag and drop any of these into the app to directly initiate the
 * upload. But having an explicit easy to reach button is also necessary for new
 * users, or for cases where drag-and-drop might not be appropriate.
 */
const UploadTypeSelector: React.FC<UploadTypeSelectorProps> = ({
    onClose,
    show,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
    uploadTypeSelectorIntent,
}) => {
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
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
                    maxWidth: "375px",
                    p: 1,
                    [theme.breakpoints.down(360)]: { p: 0 },
                }),
            }}
            onClose={dialogCloseHandler({ onClose })}
        >
            <DialogTitleWithCloseButton onClose={onClose}>
                {uploadTypeSelectorIntent ===
                UploadTypeSelectorIntent.collectPhotos
                    ? t("SELECT_PHOTOS")
                    : uploadTypeSelectorIntent ===
                        UploadTypeSelectorIntent.import
                      ? t("IMPORT")
                      : t("UPLOAD")}
            </DialogTitleWithCloseButton>
            <Box p={1.5} pt={0.5}>
                <Stack spacing={0.5}>
                    {uploadTypeSelectorIntent !==
                        UploadTypeSelectorIntent.import && (
                        <EnteMenuItem
                            onClick={uploadFiles}
                            startIcon={<FileUploadIcon />}
                            endIcon={<ChevronRight />}
                            label={t("UPLOAD_FILES")}
                        />
                    )}
                    <EnteMenuItem
                        onClick={uploadFolders}
                        startIcon={<FolderUploadIcon />}
                        endIcon={<ChevronRight />}
                        label={t("UPLOAD_DIRS")}
                    />

                    {uploadTypeSelectorIntent !==
                        UploadTypeSelectorIntent.collectPhotos && (
                        <EnteMenuItem
                            onClick={uploadGoogleTakeoutZips}
                            startIcon={<GoogleIcon />}
                            endIcon={<ChevronRight />}
                            label={t("UPLOAD_GOOGLE_TAKEOUT")}
                        />
                    )}
                </Stack>
                <Typography p={1.5} pt={4} color="text.muted">
                    {t("DRAG_AND_DROP_HINT")}
                </Typography>
            </Box>
        </Dialog>
    );
};

export default UploadTypeSelector;
