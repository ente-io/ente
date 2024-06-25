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
import { isMobileOrTable } from "utils/common/deviceDetection";
import { PublicCollectionGalleryContext } from "utils/publicCollectionGallery";

export type UploadTypeSelectorIntent = "upload" | "import" | "collect";

interface UploadTypeSelectorProps {
    /** If `true`, then the selector is shown. */
    open: boolean;
    /** Callback to indicate that the selector should be closed. */
    onClose: () => void;
    /** The particular context / scenario in which this upload is occuring. */
    intent: UploadTypeSelectorIntent;
    uploadFiles: () => void;
    uploadFolders: () => void;
    uploadGoogleTakeoutZips: () => void;
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
export const UploadTypeSelector: React.FC<UploadTypeSelectorProps> = ({
    open,
    onClose,
    intent,
    uploadFiles,
    uploadFolders,
    uploadGoogleTakeoutZips,
}) => {
    const publicCollectionGalleryContext = useContext(
        PublicCollectionGalleryContext,
    );
    const directlyShowUploadFiles = useRef(isMobileOrTable());

    useEffect(() => {
        if (
            open &&
            directlyShowUploadFiles.current &&
            publicCollectionGalleryContext.accessedThroughSharedURL
        ) {
            uploadFiles();
            onClose();
        }
    }, [open]);

    return (
        <Dialog
            open={open}
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
                {intent == "collect"
                    ? t("SELECT_PHOTOS")
                    : intent == "import"
                      ? t("IMPORT")
                      : t("UPLOAD")}
            </DialogTitleWithCloseButton>
            <Box p={1.5} pt={0.5}>
                <Stack spacing={0.5}>
                    {intent != "import" && (
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

                    {intent !== "collect" && (
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
