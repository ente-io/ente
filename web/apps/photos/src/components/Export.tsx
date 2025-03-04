import { isDesktop } from "@/base/app";
import { EnteSwitch } from "@/base/components/EnteSwitch";
import { LinkButton } from "@/base/components/LinkButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import { EllipsizedTypography } from "@/base/components/Typography";
import type { ButtonishProps } from "@/base/components/mui";
import { DialogCloseIconButton } from "@/base/components/mui/DialogCloseIconButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { useBaseContext } from "@/base/context";
import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import { EnteFile } from "@/media/file";
import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { CustomError } from "@ente/shared/error";
import FolderIcon from "@mui/icons-material/Folder";
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    DialogTitle,
    Divider,
    Stack,
    Tooltip,
    Typography,
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
    allCollectionsNameByID: Map<number, string>;
};

export const Export: React.FC<ExportProps> = ({
    open,
    onClose,
    allCollectionsNameByID,
}) => {
    const { showMiniDialog } = useBaseContext();
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
                <DialogTitle variant="h3">{t("export_data")}</DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpaceBetweenFlex>

            <DialogContent>
                <Stack>
                    <ExportDirectory
                        exportFolder={exportFolder}
                        changeExportDirectory={handleChangeExportDirectoryClick}
                        exportStage={exportStage}
                    />
                    <ContinuousExport
                        continuousExport={continuousExport}
                        toggleContinuousExport={toggleContinuousExport}
                    />
                </Stack>
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
                allCollectionsNameByID={allCollectionsNameByID}
            />
        </Dialog>
    );
};

function ExportDirectory({ exportFolder, changeExportDirectory, exportStage }) {
    return (
        <Stack
            direction="row"
            sx={{
                gap: 1,
                justifyContent: "space-between",
                alignItems: "center",
            }}
        >
            <Typography sx={{ color: "text.muted", mr: 1 }}>
                {t("destination")}
            </Typography>
            {exportFolder ? (
                <>
                    <DirectoryPath path={exportFolder} />
                    {exportStage === ExportStage.FINISHED ||
                    exportStage === ExportStage.INIT ? (
                        <ChangeDirectoryOption
                            onClick={changeExportDirectory}
                        />
                    ) : (
                        // Prevent layout shift.
                        <Box sx={{ width: "16px", height: "48px" }} />
                    )}
                </>
            ) : (
                <Button color="accent" onClick={changeExportDirectory}>
                    {t("select_folder")}
                </Button>
            )}
        </Stack>
    );
}

const DirectoryPath = ({ path }) => (
    <LinkButton onClick={() => void ensureElectron().openDirectory(path)}>
        <Tooltip title={path}>
            <EllipsizedTypography
                // Haven't found a way to get the path to ellipsize without
                // providing a maxWidth. Luckily, this is the context of the
                // desktop app where this width is should not be too off.
                sx={{ maxWidth: "262px" }}
            >
                {path}
            </EllipsizedTypography>
        </Tooltip>
    </LinkButton>
);

const ChangeDirectoryOption: React.FC<ButtonishProps> = ({ onClick }) => (
    <OverflowMenu ariaID="export-option">
        <OverflowMenuOption onClick={onClick} startIcon={<FolderIcon />}>
            {t("change_folder")}
        </OverflowMenuOption>
    </OverflowMenu>
);

function ContinuousExport({ continuousExport, toggleContinuousExport }) {
    return (
        <SpaceBetweenFlex minHeight={"48px"}>
            <Typography sx={{ color: "text.muted" }}>
                {t("sync_continuously")}
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
    allCollectionsNameByID,
}: {
    exportStage: ExportStage;
    startExport: (opts?: ExportOpts) => void;
    stopExport: () => void;
    onHide: () => void;
    lastExportTime: number;
    exportProgress: ExportProgress;
    pendingExports: EnteFile[];
    allCollectionsNameByID: Map<number, string>;
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
                    allCollectionsNameByID={allCollectionsNameByID}
                    onResync={() => startExport({ resync: true })}
                />
            );

        default:
            return <></>;
    }
};
