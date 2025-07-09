import AddIcon from "@mui/icons-material/Add";
import CheckIcon from "@mui/icons-material/Check";
import DoNotDisturbOutlinedIcon from "@mui/icons-material/DoNotDisturbOutlined";
import FolderCopyOutlinedIcon from "@mui/icons-material/FolderCopyOutlined";
import FolderOpenIcon from "@mui/icons-material/FolderOpen";
import {
    CircularProgress,
    Dialog,
    DialogContent,
    DialogTitle,
    Stack,
    Tooltip,
    Typography,
} from "@mui/material";
import { CenteredFill, SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { EllipsizedTypography } from "ente-base/components/Typography";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { ensureElectron } from "ente-base/electron";
import { basename, dirname } from "ente-base/file-name";
import type { CollectionMapping, FolderWatch } from "ente-base/types/ipc";
import { CollectionMappingChoice } from "ente-new/photos/components/CollectionMappingChoice";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import watcher from "services/watch";

/**
 * View the state of and manage folder watches.
 *
 * This is the screen that controls that "watch folder" feature in the app.
 */
export const WatchFolder: React.FC<ModalVisibilityProps> = ({
    open,
    onClose,
}) => {
    // The folders we are watching
    const [watches, setWatches] = useState<FolderWatch[] | undefined>();
    // Temporarily stash the folder path while we show a choice dialog to the
    // user to select the collection mapping.
    const [savedFolderPath, setSavedFolderPath] = useState<
        string | undefined
    >();
    const { show: showMappingChoice, props: mappingChoiceVisibilityProps } =
        useModalVisibility();

    useEffect(() => {
        void watcher.getWatches().then((ws) => setWatches(ws));
    }, []);

    useEffect(() => {
        const handleWatchFolderDrop = (e: DragEvent) => {
            if (!open) return;

            e.preventDefault();
            e.stopPropagation();

            for (const file of e.dataTransfer?.files ?? []) {
                void selectCollectionMappingAndAddWatchIfDirectory(file);
            }
        };

        addEventListener("drop", handleWatchFolderDrop);
        return () => {
            removeEventListener("drop", handleWatchFolderDrop);
        };
        // TODO:
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [open]);

    const selectCollectionMappingAndAddWatchIfDirectory = async (
        file: File,
    ) => {
        const electron = ensureElectron();
        const path = electron.pathForFile(file);
        if (await electron.fs.isDir(path)) {
            await selectCollectionMappingAndAddWatch(path);
        }
    };

    const selectCollectionMappingAndAddWatch = async (path: string) => {
        const filePaths = await ensureElectron().fs.findFiles(path);
        if (areAllInSameDirectory(filePaths)) {
            await addWatch(path, "root");
        } else {
            setSavedFolderPath(path);
            showMappingChoice();
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
        void addWatch(savedFolderPath!, mapping);
    };

    return (
        <>
            <Dialog
                open={open}
                onClose={onClose}
                fullWidth
                slotProps={{
                    paper: { sx: { height: "448px", maxWidth: "444px" } },
                }}
            >
                <SpacedRow sx={{ p: "16px 8px 0px 8px" }}>
                    <DialogTitle variant="h3">
                        {t("watched_folders")}
                    </DialogTitle>
                    <DialogCloseIconButton {...{ onClose }} />
                </SpacedRow>
                <DialogContent sx={{ flex: 1 }}>
                    <Stack sx={{ gap: 1, p: 1.5, height: "100%" }}>
                        <WatchList {...{ watches, removeWatch }} />
                        <FocusVisibleButton
                            fullWidth
                            color="accent"
                            onClick={addNewWatch}
                            startIcon={<AddIcon />}
                        >
                            {t("add_folder")}
                        </FocusVisibleButton>
                    </Stack>
                </DialogContent>
            </Dialog>
            <CollectionMappingChoice
                {...mappingChoiceVisibilityProps}
                onSelect={handleCollectionMappingSelect}
            />
        </>
    );
};

interface WatchList {
    watches: FolderWatch[] | undefined;
    removeWatch: (watch: FolderWatch) => Promise<void>;
}

const WatchList: React.FC<WatchList> = ({ watches, removeWatch }) =>
    watches?.length ? (
        <Stack sx={{ gap: 2, flex: 1, overflowY: "auto", pb: 2, pr: 1 }}>
            {watches.map((watch) => (
                <WatchEntry
                    key={watch.folderPath}
                    watch={watch}
                    removeWatch={removeWatch}
                />
            ))}
        </Stack>
    ) : (
        <NoWatches />
    );

const NoWatches: React.FC = () => (
    <CenteredFill sx={{ mb: 4 }}>
        <Stack sx={{ gap: 1.5 }}>
            <Typography variant="h6">{t("no_folders_added")}</Typography>
            <Typography variant="small" sx={{ py: 1, color: "text.muted" }}>
                {t("watch_folders_hint_1")}
            </Typography>
            <Stack direction="row" sx={{ gap: 1 }}>
                <Check />
                <Typography variant="small" sx={{ color: "text.muted" }}>
                    {t("watch_folders_hint_2")}
                </Typography>
            </Stack>
            <Stack direction="row" sx={{ gap: 1 }}>
                <Check />
                <Typography variant="small" sx={{ color: "text.muted" }}>
                    {t("watch_folders_hint_3")}
                </Typography>
            </Stack>
        </Stack>
    </CenteredFill>
);

const Check: React.FC = () => (
    <CheckIcon
        sx={{ display: "inline", fontSize: "15px", color: "stroke.muted" }}
    />
);

interface WatchEntryProps {
    watch: FolderWatch;
    removeWatch: (watch: FolderWatch) => Promise<void>;
}

const WatchEntry: React.FC<WatchEntryProps> = ({ watch, removeWatch }) => {
    const { showMiniDialog } = useBaseContext();

    const confirmStopWatching = () =>
        showMiniDialog({
            title: t("stop_watching_folder_title"),
            message: t("stop_watching_folder_message"),
            continue: {
                text: t("yes_stop"),
                color: "critical",
                action: () => removeWatch(watch),
            },
        });

    return (
        <SpacedRow sx={{ overflow: "hidden", flexShrink: 0 }}>
            <Stack direction="row" sx={{ overflow: "hidden", gap: 1.5 }}>
                {watch.collectionMapping == "root" ? (
                    <Tooltip title={t("uploaded_to_single_collection")}>
                        <FolderOpenIcon color="secondary" />
                    </Tooltip>
                ) : (
                    <Tooltip title={t("uploaded_to_separate_collections")}>
                        <FolderCopyOutlinedIcon color="secondary" />
                    </Tooltip>
                )}
                <Stack sx={{ overflow: "hidden" }}>
                    <EntryHeading watch={watch} />
                    <FolderPath>{watch.folderPath}</FolderPath>
                </Stack>
            </Stack>
            <EntryOptions {...{ confirmStopWatching }} />
        </SpacedRow>
    );
};

interface EntryHeadingProps {
    watch: FolderWatch;
}

const EntryHeading: React.FC<EntryHeadingProps> = ({
    watch: { folderPath },
}) => (
    <Stack
        direction="row"
        sx={{ gap: 1.5, alignItems: "center", justifyContent: "flex-start" }}
    >
        <Typography>{basename(folderPath)}</Typography>
        {watcher.isSyncingFolder(folderPath) && (
            <CircularProgress
                size={15}
                sx={{ flexShrink: 0, color: "stroke.muted" }}
            />
        )}
    </Stack>
);

const FolderPath: React.FC<React.PropsWithChildren> = ({ children }) => (
    <EllipsizedTypography variant="small" color="text.muted">
        {children}
    </EllipsizedTypography>
);

interface EntryOptionsProps {
    confirmStopWatching: () => void;
}

const EntryOptions: React.FC<EntryOptionsProps> = ({ confirmStopWatching }) => (
    <OverflowMenu
        ariaID={"watch-mapping-option"}
        menuPaperSxProps={{ backgroundColor: "background.paper2" }}
    >
        <OverflowMenuOption
            color="critical"
            onClick={confirmStopWatching}
            startIcon={<DoNotDisturbOutlinedIcon />}
        >
            {t("stop_watching")}
        </OverflowMenuOption>
    </OverflowMenu>
);

/**
 * Return true if all the paths in the given list are items that belong to the
 * same (arbitrary) directory.
 *
 * Empty list of paths is considered to be in the same directory.
 */
const areAllInSameDirectory = (paths: string[]) =>
    new Set(paths.map(dirname)).size == 1;
