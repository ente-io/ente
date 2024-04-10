import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { Button, Dialog, DialogContent, Stack } from "@mui/material";
import UploadStrategyChoiceModal from "components/Upload/UploadStrategyChoiceModal";
import { PICKED_UPLOAD_TYPE, UPLOAD_STRATEGY } from "constants/upload";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import watchFolderService from "services/watchFolder/watchFolderService";
import { WatchMapping } from "types/watchFolder";
import { getImportSuggestion } from "utils/upload";
import { MappingList } from "./mappingList";

interface Iprops {
    open: boolean;
    onClose: () => void;
}

export default function WatchFolder({ open, onClose }: Iprops) {
    const [mappings, setMappings] = useState<WatchMapping[]>([]);
    const [inputFolderPath, setInputFolderPath] = useState("");
    const [choiceModalOpen, setChoiceModalOpen] = useState(false);
    const appContext = useContext(AppContext);

    const electron = globalThis.electron;

    useEffect(() => {
        if (!electron) return;
        watchFolderService.getWatchMappings().then((m) => setMappings(m));
    }, []);

    useEffect(() => {
        if (
            appContext.watchFolderFiles &&
            appContext.watchFolderFiles.length > 0
        ) {
            handleFolderDrop(appContext.watchFolderFiles);
            appContext.setWatchFolderFiles(null);
        }
    }, [appContext.watchFolderFiles]);

    const handleFolderDrop = async (folders: FileList) => {
        for (let i = 0; i < folders.length; i++) {
            const folder: any = folders[i];
            const path = (folder.path as string).replace(/\\/g, "/");
            if (await watchFolderService.isFolder(path)) {
                await addFolderForWatching(path);
            }
        }
    };

    const addFolderForWatching = async (path: string) => {
        if (!electron) return;

        setInputFolderPath(path);
        const files = await electron.getDirFiles(path);
        const analysisResult = getImportSuggestion(
            PICKED_UPLOAD_TYPE.FOLDERS,
            files,
        );
        if (analysisResult.hasNestedFolders) {
            setChoiceModalOpen(true);
        } else {
            handleAddWatchMapping(UPLOAD_STRATEGY.SINGLE_COLLECTION, path);
        }
    };

    const handleAddFolderClick = async () => {
        await handleFolderSelection();
    };

    const handleFolderSelection = async () => {
        const folderPath = await watchFolderService.selectFolder();
        if (folderPath) {
            await addFolderForWatching(folderPath);
        }
    };

    const handleAddWatchMapping = async (
        uploadStrategy: UPLOAD_STRATEGY,
        folderPath?: string,
    ) => {
        folderPath = folderPath || inputFolderPath;
        await watchFolderService.addWatchMapping(
            folderPath.substring(folderPath.lastIndexOf("/") + 1),
            folderPath,
            uploadStrategy,
        );
        setInputFolderPath("");
        setMappings(await watchFolderService.getWatchMappings());
    };

    const handleRemoveWatchMapping = async (mapping: WatchMapping) => {
        await watchFolderService.removeWatchMapping(mapping.folderPath);
        setMappings(await watchFolderService.getWatchMappings());
    };

    const closeChoiceModal = () => setChoiceModalOpen(false);

    const uploadToSingleCollection = () => {
        closeChoiceModal();
        handleAddWatchMapping(UPLOAD_STRATEGY.SINGLE_COLLECTION);
    };

    const uploadToMultipleCollection = () => {
        closeChoiceModal();
        handleAddWatchMapping(UPLOAD_STRATEGY.COLLECTION_PER_FOLDER);
    };

    return (
        <>
            <Dialog
                open={open}
                onClose={onClose}
                PaperProps={{ sx: { height: "448px", maxWidth: "414px" } }}
            >
                <DialogTitleWithCloseButton
                    onClose={onClose}
                    sx={{ "&&&": { padding: "32px 16px 16px 24px" } }}
                >
                    {t("WATCHED_FOLDERS")}
                </DialogTitleWithCloseButton>
                <DialogContent sx={{ flex: 1 }}>
                    <Stack spacing={1} p={1.5} height={"100%"}>
                        <MappingList
                            mappings={mappings}
                            handleRemoveWatchMapping={handleRemoveWatchMapping}
                        />
                        <Button
                            fullWidth
                            color="accent"
                            onClick={handleAddFolderClick}
                        >
                            <span>+</span>
                            <span
                                style={{
                                    marginLeft: "8px",
                                }}
                            ></span>
                            {t("ADD_FOLDER")}
                        </Button>
                    </Stack>
                </DialogContent>
            </Dialog>
            <UploadStrategyChoiceModal
                open={choiceModalOpen}
                onClose={closeChoiceModal}
                uploadToSingleCollection={uploadToSingleCollection}
                uploadToMultipleCollection={uploadToMultipleCollection}
            />
        </>
    );
}
