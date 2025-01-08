import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import { EllipsizedTypography } from "@/base/components/Typography";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { ensureElectron } from "@/base/electron";
import { basename, dirname } from "@/base/file-name";
import type { CollectionMapping, FolderWatch } from "@/base/types/ipc";
import { CollectionMappingChoice } from "@/new/photos/components/CollectionMappingChoice";
import { DialogCloseIconButton } from "@/new/photos/components/mui/Dialog";
import { AppContext, useAppContext } from "@/new/photos/types/context";
import {
    FlexWrapper,
    SpaceBetweenFlex,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import CheckIcon from "@mui/icons-material/Check";
import DoNotDisturbOutlinedIcon from "@mui/icons-material/DoNotDisturbOutlined";
import FolderCopyOutlinedIcon from "@mui/icons-material/FolderCopyOutlined";
import FolderOpenIcon from "@mui/icons-material/FolderOpen";
import {
    Button,
    CircularProgress,
    Dialog,
    DialogContent,
    DialogTitle,
    Stack,
    Tooltip,
    Typography,
    styled,
} from "@mui/material";
import { t } from "i18next";
import React, { useContext, useEffect, useState } from "react";
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
        // eslint-disable-next-line @typescript-eslint/prefer-for-of
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
        addWatch(savedFolderPath!, mapping);
    };

    return (
        <>
            <Dialog
                open={open}
                onClose={onClose}
                fullWidth
                PaperProps={{ sx: { height: "448px", maxWidth: "414px" } }}
            >
                <SpaceBetweenFlex sx={{ p: "16px 8px 8px 8px" }}>
                    <DialogTitle variant="h3" fontWeight={"bold"}>
                        {t("watched_folders")}
                    </DialogTitle>
                    <DialogCloseIconButton {...{ onClose }} />
                </SpaceBetweenFlex>
                <DialogContent sx={{ flex: 1 }}>
                    <Stack sx={{ gap: 1, p: 1.5, height: "100%" }}>
                        <WatchList {...{ watches, removeWatch }} />
                        <Button fullWidth color="accent" onClick={addNewWatch}>
                            <span>+</span>
                            <span
                                style={{
                                    marginLeft: "8px",
                                }}
                            ></span>
                            {t("add_folder")}
                        </Button>
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

const WatchesContainer = styled("div")(() => ({
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
                <Typography variant="large" sx={{ fontWeight: "bold" }}>
                    {t("no_folders_added")}
                </Typography>
                <Typography
                    variant={"small"}
                    sx={{ py: 0.5, color: "text.muted" }}
                >
                    {t("watch_folders_hint_1")}
                </Typography>
                <Typography variant={"small"} sx={{ color: "text.muted" }}>
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("watch_folders_hint_2")}
                    </FlexWrapper>
                </Typography>
                <Typography variant={"small"} sx={{ color: "text.muted" }}>
                    <FlexWrapper gap={1}>
                        <CheckmarkIcon />
                        {t("watch_folders_hint_3")}
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
            sx={(theme) => ({
                display: "inline",
                fontSize: "15px",
                color: theme.palette.secondary.main,
            })}
        />
    );
};

interface WatchEntryProps {
    watch: FolderWatch;
    removeWatch: (watch: FolderWatch) => void;
}

const WatchEntry: React.FC<WatchEntryProps> = ({ watch, removeWatch }) => {
    const { showMiniDialog } = useAppContext();

    const confirmStopWatching = () => {
        showMiniDialog({
            title: t("stop_watching_folder_title"),
            message: t("stop_watching_folder_message"),
            continue: {
                text: t("yes_stop"),
                color: "critical",
                action: () => removeWatch(watch),
            },
        });
    };

    return (
        <SpaceBetweenFlex>
            <Stack direction="row" sx={{ overflow: "hidden" }}>
                {watch.collectionMapping === "root" ? (
                    <Tooltip title={t("uploaded_to_single_collection")}>
                        <FolderOpenIcon />
                    </Tooltip>
                ) : (
                    <Tooltip title={t("uploaded_to_separate_collections")}>
                        <FolderCopyOutlinedIcon />
                    </Tooltip>
                )}
                <EntryContainer>
                    <EntryHeading watch={watch} />
                    <FolderPath>{watch.folderPath}</FolderPath>
                </EntryContainer>
            </Stack>
            <EntryOptions {...{ confirmStopWatching }} />
        </SpaceBetweenFlex>
    );
};

const EntryContainer = styled("div")({
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
            ariaID={"watch-mapping-option"}
            menuPaperProps={{
                sx: {
                    backgroundColor: (theme) =>
                        theme.colors.background.elevated2,
                },
            }}
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
};

/**
 * Return true if all the paths in the given list are items that belong to the
 * same (arbitrary) directory.
 *
 * Empty list of paths is considered to be in the same directory.
 */
const areAllInSameDirectory = (paths: string[]) =>
    new Set(paths.map(dirname)).size == 1;
