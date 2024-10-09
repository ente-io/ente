import { EllipsizedTypography } from "@/base/components/Typography";
import { ensureElectron } from "@/base/electron";
import { basename, dirname } from "@/base/file";
import type { CollectionMapping, FolderWatch } from "@/base/types/ipc";
import { CollectionMappingChoiceDialog } from "@/new/photos/components/CollectionMappingChoiceDialog";
import { ensure } from "@/utils/ensure";
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
    styled,
} from "@mui/material";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useState } from "react";
import watcher from "services/watch";

interface WatchFolderProps {
    open: boolean;
    onClose: () => void;
}

/**
 * View the state of and manage folder watches.
 *
 * This is the screen that controls that "watch folder" feature in the app.
 */
export const WatchFolder: React.FC<WatchFolderProps> = ({ open, onClose }) => {
    // The folders we are watching
    const [watches, setWatches] = useState<FolderWatch[] | undefined>();
    // Temporarily stash the folder path while we show a choice dialog to the
    // user to select the collection mapping.
    const [savedFolderPath, setSavedFolderPath] = useState<
        string | undefined
    >();
    // True when we're showing the choice dialog to ask the user to set the
    // collection mapping.
    const [openChoiceDialog, setOpenChoiceDialog] = useState(false);

    const appContext = useContext(AppContext);

    useEffect(() => {
        watcher.getWatches().then((ws) => setWatches(ws));
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
            if (await ensureElectron().fs.isDir(path)) {
                await selectCollectionMappingAndAddWatch(path);
            }
        }
    };

    const selectCollectionMappingAndAddWatch = async (path: string) => {
        const filePaths = await ensureElectron().fs.findFiles(path);
        if (areAllInSameDirectory(filePaths)) {
            addWatch(path, "root");
        } else {
            setSavedFolderPath(path);
            setOpenChoiceDialog(true);
        }
    };

    const addWatch = (folderPath: string, mapping: CollectionMapping) =>
        watcher.addWatch(folderPath, mapping).then((ws) => setWatches(ws));

    const addNewWatch = async () => {
        const dirPath = await ensureElectron().selectDirectory();
        if (dirPath) {
            await selectCollectionMappingAndAddWatch(dirPath);
        }
    };

    const removeWatch = async (watch: FolderWatch) =>
        watcher.removeWatch(watch.folderPath).then((ws) => setWatches(ws));

    const handleCollectionMappingSelect = (mapping: CollectionMapping) => {
        setSavedFolderPath(undefined);
        addWatch(ensure(savedFolderPath), mapping);
    };

    return (
        <>
            <Dialog
                open={open}
                onClose={onClose}
                fullWidth
                PaperProps={{ sx: { height: "448px", maxWidth: "414px" } }}
            >
                <Title_>
                    <DialogTitleWithCloseButton onClose={onClose}>
                        {t("WATCHED_FOLDERS")}
                    </DialogTitleWithCloseButton>
                </Title_>
                <DialogContent sx={{ flex: 1 }}>
                    <Stack spacing={1} p={1.5} height={"100%"}>
                        <WatchList {...{ watches, removeWatch }} />
                        <Button fullWidth color="accent" onClick={addNewWatch}>
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
            <CollectionMappingChoiceDialog
                open={openChoiceDialog}
                onClose={() => setOpenChoiceDialog(false)}
                didSelect={handleCollectionMappingSelect}
            />
        </>
    );
};

const Title_ = styled("div")`
    padding: 16px 12px 16px 16px;
`;

interface WatchList {
    watches: FolderWatch[] | undefined;
    removeWatch: (watch: FolderWatch) => void;
}

const WatchList: React.FC<WatchList> = ({ watches, removeWatch }) => {
    return (watches ?? []).length === 0 ? (
        <NoWatches />
    ) : (
        <WatchesContainer>
            {watches.map((watch) => {
                return (
                    <WatchEntry
                        key={watch.folderPath}
                        watch={watch}
                        removeWatch={removeWatch}
                    />
                );
            })}
        </WatchesContainer>
    );
};

const WatchesContainer = styled(Box)(() => ({
    height: "278px",
    overflow: "auto",
    "&::-webkit-scrollbar": {
        width: "4px",
    },
}));

const NoWatches: React.FC = () => {
    return (
        <NoWatchesContainer>
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
        </NoWatchesContainer>
    );
};

const NoWatchesContainer = styled(VerticallyCentered)({
    textAlign: "left",
    alignItems: "flex-start",
    marginBottom: "32px",
});

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

interface WatchEntryProps {
    watch: FolderWatch;
    removeWatch: (watch: FolderWatch) => void;
}

const WatchEntry: React.FC<WatchEntryProps> = ({ watch, removeWatch }) => {
    const appContext = React.useContext(AppContext);

    const confirmStopWatching = () => {
        appContext.setDialogMessage({
            title: t("STOP_WATCHING_FOLDER"),
            content: t("STOP_WATCHING_DIALOG_MESSAGE"),
            close: {
                text: t("cancel"),
                variant: "secondary",
            },
            proceed: {
                action: () => removeWatch(watch),
                text: t("YES_STOP"),
                variant: "critical",
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <HorizontalFlex
                sx={{
                    overflow: "hidden",
                }}
            >
                {watch.collectionMapping === "root" ? (
                    <Tooltip title={t("UPLOADED_TO_SINGLE_COLLECTION")}>
                        <FolderOpenIcon />
                    </Tooltip>
                ) : (
                    <Tooltip title={t("UPLOADED_TO_SEPARATE_COLLECTIONS")}>
                        <FolderCopyOutlinedIcon />
                    </Tooltip>
                )}
                <EntryContainer>
                    <EntryHeading watch={watch} />
                    <FolderPath>{watch.folderPath}</FolderPath>
                </EntryContainer>
            </HorizontalFlex>
            <EntryOptions {...{ confirmStopWatching }} />
        </SpaceBetweenFlex>
    );
};

const EntryContainer = styled(Box)({
    overflow: "hidden",
    marginLeft: "12px",
    marginRight: "6px",
    marginBottom: "12px",
});

interface EntryHeadingProps {
    watch: FolderWatch;
}

const EntryHeading: React.FC<EntryHeadingProps> = ({ watch }) => {
    const folderPath = watch.folderPath;

    return (
        <FlexWrapper gap={1}>
            <Typography>{basename(folderPath)}</Typography>
            {watcher.isSyncingFolder(folderPath) && (
                <CircularProgress size={12} />
            )}
        </FlexWrapper>
    );
};

const FolderPath: React.FC<React.PropsWithChildren> = ({ children }) => (
    <EllipsizedTypography variant="small" color="text.muted">
        {children}
    </EllipsizedTypography>
);

interface EntryOptionsProps {
    confirmStopWatching: () => void;
}

const EntryOptions: React.FC<EntryOptionsProps> = ({ confirmStopWatching }) => {
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

/**
 * Return true if all the paths in the given list are items that belong to the
 * same (arbitrary) directory.
 *
 * Empty list of paths is considered to be in the same directory.
 */
const areAllInSameDirectory = (paths: string[]) =>
    new Set(paths.map(dirname)).size == 1;
