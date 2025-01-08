import { isDesktop } from "@/base/app";
import { EnteSwitch } from "@/base/components/EnteSwitch";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import type { ButtonishProps } from "@/base/components/mui";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import { EnteFile } from "@/media/file";
import { DialogCloseIconButton } from "@/new/photos/components/mui/Dialog";
import { useAppContext } from "@/new/photos/types/context";
import {
    SpaceBetweenFlex,
    VerticallyCenteredFlex,
} from "@ente/shared/components/Container";
import LinkButton from "@ente/shared/components/LinkButton";
import { CustomError } from "@ente/shared/error";
import FolderIcon from "@mui/icons-material/Folder";
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    Divider,
    Tooltip,
    Typography,
    styled,
} from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import exportService, {
    ExportStage,
    selectAndPrepareExportDirectory,
    type ExportOpts,
    type ExportProgress,
    type ExportSettings,
} from "services/export";
import ExportFinished from "./ExportFinished";
import ExportInProgress from "./ExportInProgress";
import ExportInit from "./ExportInit";

type ExportProps = ModalVisibilityProps & {
    collectionNameMap: Map<number, string>;
};

export const Export: React.FC<ExportProps> = ({
    open,
    onClose,
    collectionNameMap,
}) => {
    const { showMiniDialog } = useAppContext();
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState("");
    const [continuousExport, setContinuousExport] = useState(false);
    const [exportProgress, setExportProgress] = useState<ExportProgress>({
        success: 0,
        failed: 0,
        total: 0,
    });
    const [pendingExports, setPendingExports] = useState<EnteFile[]>([]);
    const [lastExportTime, setLastExportTime] = useState(0);

    // ====================
    // SIDE EFFECTS
    // ====================
    useEffect(() => {
        if (!isDesktop) {
            return;
        }
        try {
            exportService.setUIUpdaters({
                setExportStage,
                setExportProgress,
                setLastExportTime,
                setPendingExports,
            });
            const exportSettings: ExportSettings =
                exportService.getExportSettings();
            setExportFolder(exportSettings?.folder ?? null);
            setContinuousExport(exportSettings?.continuousExport ?? false);
            void syncExportRecord(exportSettings?.folder);
        } catch (e) {
            log.error("export on mount useEffect failed", e);
        }
    }, []);

    useEffect(() => {
        if (!open) {
            return;
        }
        void syncExportRecord(exportFolder);
    }, [open]);

    // ======================
    // HELPER FUNCTIONS
    // =======================

    const verifyExportFolderExists = async () => {
        if (!(await exportService.exportFolderExists(exportFolder))) {
            showMiniDialog({
                title: t("export_directory_does_not_exist"),
                message: (
                    <Trans
                        i18nKey={"export_directory_does_not_exist_message"}
                    />
                ),
                cancel: t("ok"),
            });
            return false;
        }
        return true;
    };

    const syncExportRecord = async (exportFolder: string): Promise<void> => {
        try {
            if (!(await exportService.exportFolderExists(exportFolder))) {
                const pendingExports =
                    await exportService.getPendingExports(null);
                setPendingExports(pendingExports);
            }
            const exportRecord =
                await exportService.getExportRecord(exportFolder);
            setExportStage(exportRecord.stage);
            setLastExportTime(exportRecord.lastAttemptTimestamp);
            const pendingExports =
                await exportService.getPendingExports(exportRecord);
            setPendingExports(pendingExports);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("syncExportRecord failed", e);
            }
        }
    };

    // =============
    // UI functions
    // =============

    const handleChangeExportDirectoryClick = async () => {
        const newFolder = await selectAndPrepareExportDirectory();
        if (!newFolder) return;

        log.info(`Export folder changed to ${newFolder}`);
        exportService.updateExportSettings({ folder: newFolder });
        setExportFolder(newFolder);
        await syncExportRecord(newFolder);
    };

    const toggleContinuousExport = async () => {
        if (!(await verifyExportFolderExists())) return;

        const newContinuousExport = !continuousExport;
        if (newContinuousExport) {
            exportService.enableContinuousExport();
        } else {
            exportService.disableContinuousExport();
        }
        exportService.updateExportSettings({
            continuousExport: newContinuousExport,
        });
        setContinuousExport(newContinuousExport);
    };

    const startExport = async (opts?: ExportOpts) => {
        if (!(await verifyExportFolderExists())) return;

        await exportService.scheduleExport(opts ?? {});
    };

    const stopExport = () => {
        void exportService.stopRunningExport();
    };

    return (
        <Dialog {...{ open, onClose }} maxWidth="xs" fullWidth>
            <SpaceBetweenFlex sx={{ p: "12px 4px 0px 0px" }}>
                <DialogTitle variant="h3" fontWeight={"bold"}>
                    {t("export_data")}
                </DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpaceBetweenFlex>

            <DialogContent>
                <ExportDirectory
                    exportFolder={exportFolder}
                    changeExportDirectory={handleChangeExportDirectoryClick}
                    exportStage={exportStage}
                />
                <ContinuousExport
                    continuousExport={continuousExport}
                    toggleContinuousExport={toggleContinuousExport}
                />
            </DialogContent>
            <Divider />
            <ExportDynamicContent
                exportStage={exportStage}
                startExport={startExport}
                stopExport={stopExport}
                onHide={onClose}
                lastExportTime={lastExportTime}
                exportProgress={exportProgress}
                pendingExports={pendingExports}
                collectionNameMap={collectionNameMap}
            />
        </Dialog>
    );
};

function ExportDirectory({ exportFolder, changeExportDirectory, exportStage }) {
    return (
        <SpaceBetweenFlex minHeight={"48px"}>
            <Typography sx={{ color: "text.muted", mr: "16px" }}>
                {t("destination")}
            </Typography>
            <>
                {!exportFolder ? (
                    <Button color={"accent"} onClick={changeExportDirectory}>
                        {t("select_folder")}
                    </Button>
                ) : (
                    <VerticallyCenteredFlex>
                        <DirectoryPath width={262} path={exportFolder} />
                        {exportStage === ExportStage.FINISHED ||
                        exportStage === ExportStage.INIT ? (
                            <ChangeDirectoryOption
                                onClick={changeExportDirectory}
                            />
                        ) : (
                            <Box sx={{ width: "16px" }} />
                        )}
                    </VerticallyCenteredFlex>
                )}
            </>
        </SpaceBetweenFlex>
    );
}

const DirectoryPath = ({ width, path }) => {
    const handleClick = async () => {
        try {
            await ensureElectron().openDirectory(path);
        } catch (e) {
            log.error("openDirectory failed", e);
        }
    };
    return (
        <DirectoryPathContainer width={width} onClick={handleClick}>
            <Tooltip title={path}>
                <span>{path}</span>
            </Tooltip>
        </DirectoryPathContainer>
    );
};

const DirectoryPathContainer = styled(LinkButton)(
    ({ width }) => `
    width: ${width}px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    /* Beginning of string */
    direction: rtl;
    text-align: left;
`,
);

const ChangeDirectoryOption: React.FC<ButtonishProps> = ({ onClick }) => (
    <OverflowMenu ariaID="export-option" triggerButtonProps={{ sx: { ml: 1 } }}>
        <OverflowMenuOption onClick={onClick} startIcon={<FolderIcon />}>
            {t("change_folder")}
        </OverflowMenuOption>
    </OverflowMenu>
);

function ContinuousExport({ continuousExport, toggleContinuousExport }) {
    return (
        <SpaceBetweenFlex minHeight={"48px"}>
            <Typography sx={{ color: "text.muted" }}>
                {t("CONTINUOUS_EXPORT")}
            </Typography>
            <Box>
                <EnteSwitch
                    color="accent"
                    checked={continuousExport}
                    onChange={toggleContinuousExport}
                />
            </Box>
        </SpaceBetweenFlex>
    );
}

const ExportDynamicContent = ({
    exportStage,
    startExport,
    stopExport,
    onHide,
    lastExportTime,
    exportProgress,
    pendingExports,
    collectionNameMap,
}: {
    exportStage: ExportStage;
    startExport: (opts?: ExportOpts) => void;
    stopExport: () => void;
    onHide: () => void;
    lastExportTime: number;
    exportProgress: ExportProgress;
    pendingExports: EnteFile[];
    collectionNameMap: Map<number, string>;
}) => {
    switch (exportStage) {
        case ExportStage.INIT:
            return <ExportInit startExport={startExport} />;

        case ExportStage.MIGRATION:
        case ExportStage.STARTING:
        case ExportStage.EXPORTING_FILES:
        case ExportStage.RENAMING_COLLECTION_FOLDERS:
        case ExportStage.TRASHING_DELETED_FILES:
        case ExportStage.TRASHING_DELETED_COLLECTIONS:
            return (
                <ExportInProgress
                    exportStage={exportStage}
                    exportProgress={exportProgress}
                    stopExport={stopExport}
                    closeExportDialog={onHide}
                />
            );
        case ExportStage.FINISHED:
            return (
                <ExportFinished
                    onHide={onHide}
                    lastExportTime={lastExportTime}
                    pendingExports={pendingExports}
                    collectionNameMap={collectionNameMap}
                    onResync={() => startExport({ resync: true })}
                />
            );

        default:
            return <></>;
    }
};
