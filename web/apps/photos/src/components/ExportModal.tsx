import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import ChangeDirectoryOption from "@ente/shared/components/ChangeDirectoryOption";
import {
    SpaceBetweenFlex,
    VerticallyCenteredFlex,
} from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { CustomError } from "@ente/shared/error";
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    Divider,
    Switch,
    Typography,
} from "@mui/material";
import { t } from "i18next";
import isElectron from "is-electron";
import { AppContext } from "pages/_app";
import { useContext, useEffect, useState } from "react";
import exportService, {
    ExportStage,
    selectAndPrepareExportDirectory,
    type ExportOpts,
} from "services/export";
import { ExportProgress, ExportSettings } from "types/export";
import { getExportDirectoryDoesNotExistMessage } from "utils/ui";
import { DirectoryPath } from "./Directory";
import ExportFinished from "./ExportFinished";
import ExportInProgress from "./ExportInProgress";
import ExportInit from "./ExportInit";

interface Props {
    show: boolean;
    onHide: () => void;
    collectionNameMap: Map<number, string>;
}
export default function ExportModal(props: Props) {
    const appContext = useContext(AppContext);
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
        if (!isElectron()) {
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
        if (!props.show) {
            return;
        }
        void syncExportRecord(exportFolder);
    }, [props.show]);

    // ======================
    // HELPER FUNCTIONS
    // =======================

    const verifyExportFolderExists = async () => {
        if (!(await exportService.exportFolderExists(exportFolder))) {
            appContext.setDialogMessage(
                getExportDirectoryDoesNotExistMessage(),
            );
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
        <Dialog open={props.show} onClose={props.onHide} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t("EXPORT_DATA")}
            </DialogTitleWithCloseButton>
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
                onHide={props.onHide}
                lastExportTime={lastExportTime}
                exportProgress={exportProgress}
                pendingExports={pendingExports}
                collectionNameMap={props.collectionNameMap}
            />
        </Dialog>
    );
}

function ExportDirectory({ exportFolder, changeExportDirectory, exportStage }) {
    return (
        <SpaceBetweenFlex minHeight={"48px"}>
            <Typography color="text.muted" mr={"16px"}>
                {t("DESTINATION")}
            </Typography>
            <>
                {!exportFolder ? (
                    <Button color={"accent"} onClick={changeExportDirectory}>
                        {t("SELECT_FOLDER")}
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

function ContinuousExport({ continuousExport, toggleContinuousExport }) {
    return (
        <SpaceBetweenFlex minHeight={"48px"}>
            <Typography color="text.muted">{t("CONTINUOUS_EXPORT")}</Typography>
            <Box>
                <Switch
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
