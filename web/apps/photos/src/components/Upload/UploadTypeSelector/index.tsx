import { t } from "i18next";
import { useContext, useEffect, useRef } from "react";

import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import ChevronRight from "@mui/icons-material/ChevronRight";
import GoogleIcon from "@mui/icons-material/Google";
import { default as FileUploadIcon } from "@mui/icons-material/ImageOutlined";
import { default as FolderUploadIcon } from "@mui/icons-material/PermMediaOutlined";
import { Box, Dialog, Stack, Typography } from "@mui/material";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { UploadTypeSelectorIntent } from "types/gallery";
import { isMobileOrTable } from "utils/common/deviceDetection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";
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
}
