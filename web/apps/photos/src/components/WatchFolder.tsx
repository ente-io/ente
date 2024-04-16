import {
    FlexWrapper,
    HorizontalFlex,
    SpaceBetweenFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import CheckIcon from "@mui/icons-material/Check";
import DoNotDisturbOutlinedIcon from "@mui/icons-material/DoNotDisturbOutlined";
import FolderCopyOutlinedIcon from "@mui/icons-material/FolderCopyOutlined";
import FolderOpenIcon from "@mui/icons-material/FolderOpen";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import {
    Box,
    Button,
    CircularProgress,
    Dialog,
    DialogContent,
    Stack,
    Tooltip,
    Typography,
} from "@mui/material";
import { styled } from "@mui/material/styles";
import UploadStrategyChoiceModal from "components/Upload/UploadStrategyChoiceModal";
import { PICKED_UPLOAD_TYPE, UPLOAD_STRATEGY } from "constants/upload";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import watchFolderService from "services/watch";
import { WatchMapping } from "types/watchFolder";
import { getImportSuggestion } from "utils/upload";

interface WatchFolderProps {
    open: boolean;
    onClose: () => void;
}

export const WatchFolder: React.FC<WatchFolderProps> = ({ open, onClose }) => {
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
};

const MappingsContainer = styled(Box)(() => ({
    height: "278px",
    overflow: "auto",
    "&::-webkit-scrollbar": {
        width: "4px",
    },
}));

const NoMappingsContainer = styled(VerticallyCentered)({
    textAlign: "left",
    alignItems: "flex-start",
    marginBottom: "32px",
});

const EntryContainer = styled(Box)({
    marginLeft: "12px",
    marginRight: "6px",
    marginBottom: "12px",
});

interface MappingListProps {
    mappings: WatchMapping[];
    handleRemoveWatchMapping: (value: WatchMapping) => void;
}

const MappingList: React.FC<MappingListProps> = ({
    mappings,
    handleRemoveWatchMapping,
}) => {
    return mappings.length === 0 ? (
        <NoMappingsContent />
    ) : (
        <MappingsContainer>
            {mappings.map((mapping) => {
                return (
                    <MappingEntry
                        key={mapping.rootFolderName}
                        mapping={mapping}
                        handleRemoveMapping={handleRemoveWatchMapping}
                    />
                );
            })}
        </MappingsContainer>
    );
};

const NoMappingsContent: React.FC = () => {
    return (
        <NoMappingsContainer>
            <Stack spacing={1}>
                <Typography variant="large" fontWeight={"bold"}>
                    {t("NO_FOLDERS_ADDED")}
                </Typography>
                <Typography py={0.5} variant={"small"} color="text.muted">
                    {t("FOLDERS_AUTOMATICALLY_MONITORED")}
                </Typography>
                <Typography variant={"small"} color="text.muted">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("UPLOAD_NEW_FILES_TO_ENTE")}
                    </FlexWrapper>
                </Typography>
                <Typography variant={"small"} color="text.muted">
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("REMOVE_DELETED_FILES_FROM_ENTE")}
                    </FlexWrapper>
                </Typography>
            </Stack>
        </NoMappingsContainer>
    );
};

const CheckmarkIcon: React.FC = () => {
    return (
        <CheckIcon
            fontSize="small"
            sx={{
                display: "inline",
                fontSize: "15px",

                color: (theme) => theme.palette.secondary.main,
            }}
        />
    );
};

interface MappingEntryProps {
    mapping: WatchMapping;
    handleRemoveMapping: (mapping: WatchMapping) => void;
}

const MappingEntry: React.FC<MappingEntryProps> = ({
    mapping,
    handleRemoveMapping,
}) => {
    const appContext = React.useContext(AppContext);

    const stopWatching = () => {
        handleRemoveMapping(mapping);
    };

    const confirmStopWatching = () => {
        appContext.setDialogMessage({
            title: t("STOP_WATCHING_FOLDER"),
            content: t("STOP_WATCHING_DIALOG_MESSAGE"),
            close: {
                text: t("CANCEL"),
                variant: "secondary",
            },
            proceed: {
                action: stopWatching,
                text: t("YES_STOP"),
                variant: "critical",
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <HorizontalFlex>
                {mapping &&
                mapping.uploadStrategy === UPLOAD_STRATEGY.SINGLE_COLLECTION ? (
                    <Tooltip title={t("UPLOADED_TO_SINGLE_COLLECTION")}>
                        <FolderOpenIcon />
                    </Tooltip>
                ) : (
                    <Tooltip title={t("UPLOADED_TO_SEPARATE_COLLECTIONS")}>
                        <FolderCopyOutlinedIcon />
                    </Tooltip>
                )}
                <EntryContainer>
                    <EntryHeading mapping={mapping} />
                    <Typography color="text.muted" variant="small">
                        {mapping.folderPath}
                    </Typography>
                </EntryContainer>
            </HorizontalFlex>
            <MappingEntryOptions confirmStopWatching={confirmStopWatching} />
        </SpaceBetweenFlex>
    );
};

interface EntryHeadingProps {
    mapping: WatchMapping;
}

const EntryHeading: React.FC<EntryHeadingProps> = ({ mapping }) => {
    const appContext = useContext(AppContext);
    return (
        <FlexWrapper gap={1}>
            <Typography>{mapping.rootFolderName}</Typography>
            {appContext.isFolderSyncRunning &&
                watchFolderService.isMappingSyncInProgress(mapping) && (
                    <CircularProgress size={12} />
                )}
        </FlexWrapper>
    );
};

interface MappingEntryOptionsProps {
    confirmStopWatching: () => void;
}

const MappingEntryOptions: React.FC<MappingEntryOptionsProps> = ({
    confirmStopWatching,
}) => {
    return (
        <OverflowMenu
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        theme.colors.background.elevated2,
                },
            }}
            ariaControls={"watch-mapping-option"}
            triggerButtonIcon={<MoreHorizIcon />}
        >
            <OverflowMenuOption
                color="critical"
                onClick={confirmStopWatching}
                startIcon={<DoNotDisturbOutlinedIcon />}
            >
                {t("STOP_WATCHING")}
            </OverflowMenuOption>
        </OverflowMenu>
    );
};
