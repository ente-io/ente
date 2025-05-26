import FolderIcon from "@mui/icons-material/Folder";
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    LinearProgress,
    Stack,
    Tooltip,
    Typography,
} from "@mui/material";
import { isDesktop } from "ente-base/app";
import { EnteSwitch } from "ente-base/components/EnteSwitch";
import { LinkButton } from "ente-base/components/LinkButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { EllipsizedTypography } from "ente-base/components/Typography";
import { SpacedRow } from "ente-base/components/containers";
import type { ButtonishProps } from "ente-base/components/mui";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { ensureElectron } from "ente-base/electron";
import { formattedNumber } from "ente-base/i18n";
import { formattedDateTime } from "ente-base/i18n-date";
import log from "ente-base/log";
import { EnteFile } from "ente-media/file";
import {
    FlexWrapper,
    SpaceBetweenFlex,
    VerticallyCentered,
} from "ente-shared/components/Container";
import { CustomError } from "ente-shared/error";
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
import ExportInit from "./ExportInit";
import ExportPendingList from "./ExportPendingList";

type ExportProps = ModalVisibilityProps & {
    allCollectionsNameByID: Map<number, string>;
};

export const Export: React.FC<ExportProps> = ({
    open,
    onClose,
    allCollectionsNameByID,
}) => {
    const { showMiniDialog } = useBaseContext();
    const [exportStage, setExportStage] = useState<ExportStage>(
        ExportStage.init,
    );
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
            <SpacedRow sx={{ p: "12px 4px 0px 0px" }}>
                <DialogTitle variant="h3">{t("export_data")}</DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpacedRow>

            <DialogContent>
                <Stack>
                    <ExportDirectory
                        exportFolder={exportFolder}
                        changeExportDirectory={handleChangeExportDirectoryClick}
                        exportStage={exportStage}
                    />
                    <ContinuousExport
                        enabled={continuousExport}
                        onToggle={() => void toggleContinuousExport()}
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
                    {exportStage === ExportStage.finished ||
                    exportStage === ExportStage.init ? (
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

interface ContinuousExportProps {
    /**
     * If `true`, then continuous export is shown as enabled.
     */
    enabled: boolean;
    /**
     * Called when the user wants to toggle the current value of
     * {@link enabled}.
     */
    onToggle: () => void;
}

const ContinuousExport: React.FC<ContinuousExportProps> = ({
    enabled,
    onToggle,
}) => (
    <SpacedRow sx={{ minHeight: "48px", mt: 1 }}>
        <Typography sx={{ color: "text.muted" }}>
            {t("sync_continuously")}
        </Typography>
        <Box>
            <EnteSwitch color="accent" checked={enabled} onChange={onToggle} />
        </Box>
    </SpacedRow>
);

interface ExportDynamicContentProps {
    exportStage: ExportStage;
    startExport: (opts?: ExportOpts) => void;
    stopExport: () => void;
    onHide: () => void;
    lastExportTime: number;
    exportProgress: ExportProgress;
    pendingExports: EnteFile[];
    allCollectionsNameByID: Map<number, string>;
}

const ExportDynamicContent: React.FC<ExportDynamicContentProps> = ({
    exportStage,
    startExport,
    stopExport,
    onHide,
    lastExportTime,
    exportProgress,
    pendingExports,
    allCollectionsNameByID,
}) => {
    switch (exportStage) {
        case ExportStage.init:
            return <ExportInit startExport={startExport} />;

        case ExportStage.migration:
        case ExportStage.starting:
        case ExportStage.exportingFiles:
        case ExportStage.renamingCollectionFolders:
        case ExportStage.trashingDeletedFiles:
        case ExportStage.trashingDeletedCollections:
            return (
                <ExportInProgress
                    exportStage={exportStage}
                    exportProgress={exportProgress}
                    onClose={onHide}
                    onStop={stopExport}
                />
            );
        case ExportStage.finished:
            return (
                <ExportFinished
                    pendingExports={pendingExports}
                    lastExportTime={lastExportTime}
                    allCollectionsNameByID={allCollectionsNameByID}
                    onClose={onHide}
                    onResync={() => startExport({ resync: true })}
                />
            );

        default:
            return <></>;
    }
};

interface ExportInProgressProps {
    exportStage: ExportStage;
    exportProgress: ExportProgress;
    /**
     * Called when the user wants to stop the export.
     */
    onStop: () => void;
    /**
     * Called when the user closes the export dialog.
     * @returns
     */
    onClose: () => void;
}

const ExportInProgress: React.FC<ExportInProgressProps> = ({
    exportStage,
    exportProgress,
    onClose,
    onStop,
}) => (
    <>
        <DialogContent>
            <VerticallyCentered>
                <Typography sx={{ mb: 1.5 }}>
                    {exportStage === ExportStage.starting ? (
                        t("export_starting")
                    ) : exportStage === ExportStage.migration ? (
                        t("export_preparing")
                    ) : exportStage ===
                      ExportStage.renamingCollectionFolders ? (
                        t("export_renaming_album_folders")
                    ) : exportStage === ExportStage.trashingDeletedFiles ? (
                        t("export_trashing_deleted_files")
                    ) : exportStage ===
                      ExportStage.trashingDeletedCollections ? (
                        t("export_trashing_deleted_albums")
                    ) : (
                        <Typography
                            component="span"
                            sx={{ color: "text.muted" }}
                        >
                            <Trans
                                i18nKey={"export_progress"}
                                components={{
                                    a: (
                                        <Typography
                                            component="span"
                                            sx={{
                                                color: "text.base",
                                                pr: "1rem",
                                                wordSpacing: "1rem",
                                            }}
                                        />
                                    ),
                                }}
                                values={{ progress: exportProgress }}
                            />
                        </Typography>
                    )}
                </Typography>
                <FlexWrapper px={1}>
                    {exportStage === ExportStage.starting ||
                    exportStage === ExportStage.migration ||
                    exportStage === ExportStage.renamingCollectionFolders ||
                    exportStage === ExportStage.trashingDeletedFiles ||
                    exportStage === ExportStage.trashingDeletedCollections ? (
                        <LinearProgress />
                    ) : (
                        <LinearProgress
                            variant="determinate"
                            value={Math.round(
                                ((exportProgress.success +
                                    exportProgress.failed) *
                                    100) /
                                    exportProgress.total,
                            )}
                        />
                    )}
                </FlexWrapper>
            </VerticallyCentered>
        </DialogContent>
        <DialogActions>
            <FocusVisibleButton fullWidth color="secondary" onClick={onClose}>
                {t("close")}
            </FocusVisibleButton>
            <FocusVisibleButton fullWidth color="critical" onClick={onStop}>
                {t("stop")}
            </FocusVisibleButton>
        </DialogActions>
    </>
);

interface ExportFinishedProps {
    pendingExports: EnteFile[];
    lastExportTime: number;
    allCollectionsNameByID: Map<number, string>;
    onClose: () => void;
    /**
     * Called when the user presses the "Resync" button.
     */
    onResync: () => void;
}

const ExportFinished: React.FC<ExportFinishedProps> = ({
    pendingExports,
    lastExportTime,
    allCollectionsNameByID,
    onClose,
    onResync,
}) => {
    const [pendingFileListView, setPendingFileListView] =
        useState<boolean>(false);

    const openPendingFileList = () => {
        setPendingFileListView(true);
    };

    const closePendingFileList = () => {
        setPendingFileListView(false);
    };
    return (
        <>
            <DialogContent>
                <Stack sx={{ pr: 2 }}>
                    <SpaceBetweenFlex minHeight={"48px"}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("pending_items")}
                        </Typography>
                        {pendingExports.length ? (
                            <LinkButton onClick={openPendingFileList}>
                                {formattedNumber(pendingExports.length)}
                            </LinkButton>
                        ) : (
                            <Typography>
                                {formattedNumber(pendingExports.length)}
                            </Typography>
                        )}
                    </SpaceBetweenFlex>
                    <SpaceBetweenFlex minHeight={"48px"}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("last_export_time")}
                        </Typography>
                        <Typography>
                            {lastExportTime
                                ? formattedDateTime(new Date(lastExportTime))
                                : t("never")}
                        </Typography>
                    </SpaceBetweenFlex>
                </Stack>
            </DialogContent>
            <DialogActions>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={onClose}
                >
                    {t("close")}
                </FocusVisibleButton>
                <FocusVisibleButton fullWidth onClick={onResync}>
                    {t("export_again")}
                </FocusVisibleButton>
            </DialogActions>
            <ExportPendingList
                pendingExports={pendingExports}
                allCollectionsNameByID={allCollectionsNameByID}
                isOpen={pendingFileListView}
                onClose={closePendingFileList}
            />
        </>
    );
};
