import { useIsTouchscreen } from "@/base/hooks";
import { FocusVisibleButton } from "@/new/photos/components/FocusVisibleButton";
import { SpaceBetweenFlex } from "@/new/photos/components/mui";
import { DialogCloseIconButton } from "@/new/photos/components/mui/Dialog";
import DialogTitleWithCloseButton, {
    dialogCloseHandler,
} from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import ChevronRight from "@mui/icons-material/ChevronRight";
import GoogleIcon from "@mui/icons-material/Google";
import { default as FileUploadIcon } from "@mui/icons-material/ImageOutlined";
import { default as FolderUploadIcon } from "@mui/icons-material/PermMediaOutlined";
import {
    Box,
    Dialog,
    DialogTitle,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import React, { useContext, useEffect, useState } from "react";
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

    // Directly show the file selector for the public albums app on likely
    // mobile devices.
    const directlyShowUploadFiles = useIsTouchscreen();

    useEffect(() => {
        if (
            open &&
            directlyShowUploadFiles &&
            publicCollectionGalleryContext.accessedThroughSharedURL
        ) {
            uploadFiles();
            onClose();
        }
    }, [open]);

    const handleSelect = (option: OptionType) => {
        switch (option) {
            case "files":
                uploadFiles();
                break;
            case "folders":
                uploadFolders();
                break;
            case "zips":
                uploadGoogleTakeoutZips();
                break;
        }
    };

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
            onClose={dialogCloseHandler({ onClose: onClose })}
        >
            <Options
                intent={intent}
                onSelect={handleSelect}
                onClose={onClose}
            />
        </Dialog>
    );
};

type OptionType = "files" | "folders" | "zips";

type OptionsProps = {
    intent: UploadTypeSelectorIntent;
    /** Called when the user selects one of the provided options. */
    onSelect: (option: OptionType) => void;
    /** Called when the dialog should be closed. */
    onClose: () => void;
};

export const Options: React.FC<OptionsProps> = ({
    intent,
    onSelect,
    onClose,
}) => {
    // [Note: Dialog state remains preseved on reopening]
    //
    // Keep dialog content specific state here, in a separate component, so that
    // this state is not tied to the lifetime of the dialog.
    //
    // If we don't do this, then the dialog retains whatever it was doing when
    // it was last closed. Sometimes that is desirable, but sometimes not, and
    // in the latter cases moving the instance specific state to a child works.

    const [showTakeoutOptions, setShowTakeoutOptions] = useState(false);

    const handleTakeoutClose = () => {
        setShowTakeoutOptions(false);
    };

    const handleSelect = (option: OptionType) => {
        switch (option) {
            case "files":
                onSelect("files");
                break;
            case "folders":
                onSelect("folders");
                break;
            case "zips":
                !showTakeoutOptions
                    ? setShowTakeoutOptions(true)
                    : onSelect("zips");
                break;
        }
    };

    return !showTakeoutOptions ? (
        <DefaultOptions {...{ intent, onClose }} onSelect={handleSelect} />
    ) : (
        <TakeoutOptions onSelect={handleSelect} onClose={handleTakeoutClose} />
    );
};

const DefaultOptions: React.FC<OptionsProps> = ({
    intent,
    onClose,
    onSelect,
}) => {
    return (
        <>
            <DialogTitleWithCloseButton onClose={onClose}>
                {intent == "collect"
                    ? t("select_photos")
                    : intent == "import"
                      ? t("import")
                      : t("upload")}
            </DialogTitleWithCloseButton>

            <Box p={1.5} pt={0.5}>
                <Stack spacing={0.5}>
                    {intent != "import" && (
                        <EnteMenuItem
                            onClick={() => onSelect("files")}
                            startIcon={<FileUploadIcon />}
                            endIcon={<ChevronRight />}
                            label={t("file")}
                        />
                    )}
                    <EnteMenuItem
                        onClick={() => onSelect("folders")}
                        startIcon={<FolderUploadIcon />}
                        endIcon={<ChevronRight />}
                        label={t("folder")}
                    />
                    {intent !== "collect" && (
                        <EnteMenuItem
                            onClick={() => onSelect("zips")}
                            startIcon={<GoogleIcon />}
                            endIcon={<ChevronRight />}
                            label={t("google_takeout")}
                        />
                    )}
                </Stack>
                <Typography
                    p={1.5}
                    pt={4}
                    color="text.muted"
                    sx={{ textAlign: "center" }}
                >
                    {t("drag_and_drop_hint")}
                </Typography>
            </Box>
        </>
    );
};

const TakeoutOptions: React.FC<Omit<OptionsProps, "intent">> = ({
    onSelect,
    onClose,
}) => {
    return (
        <>
            <SpaceBetweenFlex sx={{ padding: "8px 8px 0px 0" }}>
                <DialogTitle variant="h5">{t("google_takeout")}</DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpaceBetweenFlex>

            <Stack sx={{ padding: "12px", gap: "20px" }}>
                <Stack gap={1}>
                    <FocusVisibleButton
                        color="accent"
                        fullWidth
                        onClick={() => onSelect("folders")}
                    >
                        {t("select_folder")}
                    </FocusVisibleButton>
                    <FocusVisibleButton
                        color="secondary"
                        fullWidth
                        onClick={() => onSelect("zips")}
                    >
                        {t("select_zips")}
                    </FocusVisibleButton>
                    <Link
                        href="https://help.ente.io/photos/migration/from-google-photos/"
                        target="_blank"
                        rel="noopener"
                    >
                        <FocusVisibleButton color="secondary" fullWidth>
                            {t("faq")}
                        </FocusVisibleButton>
                    </Link>
                </Stack>

                <Typography variant="small" color="text.muted" pb={1}>
                    {t("takeout_hint")}
                </Typography>
            </Stack>
        </>
    );
};
