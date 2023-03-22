import isElectron from 'is-electron';
import React, { useEffect, useState, useContext } from 'react';
import exportService from 'services/exportService';
import { ExportProgress, ExportStats } from 'types/export';
import { getLocalFiles } from 'services/fileService';
import {
    Box,
    Button,
    Dialog,
    DialogContent,
    Divider,
    styled,
    Tooltip,
    Typography,
} from '@mui/material';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { SpaceBetweenFlex, VerticallyCenteredFlex } from './Container';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';
import FolderIcon from '@mui/icons-material/Folder';
import { ExportStage } from 'constants/export';
import DialogTitleWithCloseButton from './DialogBox/TitleWithCloseButton';
import MoreHoriz from '@mui/icons-material/MoreHoriz';
import OverflowMenu from './OverflowMenu/menu';
import { OverflowMenuOption } from './OverflowMenu/option';
import { AppContext } from 'pages/_app';
import { getExportDirectoryDoesNotExistMessage } from 'utils/ui';
import { t } from 'i18next';
import { getUserPersonalFiles } from 'utils/file';

const ExportFolderPathContainer = styled('span')`
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;

    /* Beginning of string */
    direction: rtl;
    text-align: left;
`;

interface Props {
    show: boolean;
    onHide: () => void;
}
export default function ExportModal(props: Props) {
    const appContext = useContext(AppContext);
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState('');
    const [totalFileCount, setTotalFileCount] = useState(0);
    const [exportProgress, setExportProgress] = useState<ExportProgress>({
        current: 0,
        total: 0,
    });
    const [exportStats, setExportStats] = useState<ExportStats>({
        failed: 0,
        success: 0,
    });
    const [lastExportTime, setLastExportTime] = useState(0);

    // ====================
    // SIDE EFFECTS
    // ====================
    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        try {
            setExportFolder(getData(LS_KEYS.EXPORT)?.folder);
        } catch (e) {
            logError(e, 'error in exportModal');
        }
    }, []);

    useEffect(() => {
        if (!exportFolder) {
            return;
        }
        const main = async () => {
            try {
                const exportInfo = await exportService.getExportRecord();
                setExportStage(exportInfo?.stage ?? ExportStage.INIT);
                setLastExportTime(exportInfo?.lastAttemptTimestamp);
                setExportStats({
                    success: exportInfo?.exportedFiles?.length ?? 0,
                    failed: exportInfo?.failedFiles?.length ?? 0,
                });
                if (exportInfo?.stage === ExportStage.INPROGRESS) {
                    await startExport();
                }
            } catch (e) {
                logError(e, 'error handling exportFolder change');
            }
        };
        void main();
    }, [exportFolder]);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        void updateTotalFileCount();
    }, [props.show]);

    const updateTotalFileCount = async () => {
        try {
            const userPersonalFiles = getUserPersonalFiles(
                await getLocalFiles()
            );
            setTotalFileCount(userPersonalFiles?.length ?? 0);
        } catch (e) {
            logError(e, 'updateTotalFileCount failed');
        }
    };

    // =============
    // STATE UPDATERS
    // ==============
    const updateExportFolder = (newFolder: string) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { folder: newFolder });
    };

    const updateExportStage = async (newStage: ExportStage) => {
        setExportStage(newStage);
        await exportService.updateExportRecord({ stage: newStage });
    };

    const updateExportTime = async (newTime: number) => {
        setLastExportTime(newTime);
        await exportService.updateExportRecord({
            lastAttemptTimestamp: newTime,
        });
    };

    // ======================
    // HELPER FUNCTIONS
    // =========================

    const preExportRun = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        const exportFolderExists = exportService.exists(exportFolder);
        if (!exportFolderExists) {
            appContext.setDialogMessage(
                getExportDirectoryDoesNotExistMessage()
            );
            return;
        }
        await updateExportStage(ExportStage.INPROGRESS);
    };

    const postExportRun = async () => {
        await updateExportStage(ExportStage.FINISHED);
        await updateExportTime(Date.now());
        await syncExportStatsWithRecord();
    };

    const syncExportStatsWithRecord = async () => {
        const exportRecord = await exportService.getExportRecord();
        const failed = exportRecord?.failedFiles?.length ?? 0;
        const success = exportRecord?.exportedFiles?.length ?? 0;
        setExportStats({ failed, success });
    };

    // =============
    // UI functions
    // =============

    const changeExportDirectory = async () => {
        try {
            const newFolder = await exportService.selectExportDirectory();
            if (newFolder) {
                updateExportFolder(newFolder);
            }
        } catch (e) {
            logError(e, 'selectExportDirectory failed');
        }
    };

    const startExport = async () => {
        try {
            await preExportRun();

            const exportRecord = await exportService.getExportRecord();
            const exportedFileCount = exportRecord?.exportedFiles?.length ?? 0;
            setExportProgress({
                current: exportedFileCount,
                total: totalFileCount,
            });

            const updateExportStatsWithOffset = (current: number) =>
                setExportProgress({
                    current: exportedFileCount + current,
                    total: totalFileCount,
                });
            await exportService.exportFiles(updateExportStatsWithOffset);

            await postExportRun();
        } catch (e) {
            logError(e, 'resumeExport failed');
        }
    };

    const stopExport = async () => {
        try {
            exportService.stopRunningExport();
            await postExportRun();
        } catch (e) {
            logError(e, 'stopExport failed');
        }
    };

    const startExportHandler = () => {
        void startExport();
    };
    const stopExportHandler = () => {
        void stopExport();
    };

    const ExportDynamicContent = () => {
        switch (exportStage) {
            case ExportStage.INIT:
                return <ExportInit startExport={startExportHandler} />;

            case ExportStage.INPROGRESS:
                return (
                    <ExportInProgress
                        exportStage={exportStage}
                        exportProgress={exportProgress}
                        stopExport={stopExportHandler}
                        closeExportDialog={props.onHide}
                    />
                );
            case ExportStage.FINISHED:
                return (
                    <ExportFinished
                        onHide={props.onHide}
                        lastExportTime={lastExportTime}
                        exportStats={exportStats}
                        startExport={startExportHandler}
                    />
                );

            default:
                return <></>;
        }
    };

    return (
        <Dialog open={props.show} onClose={props.onHide} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t('EXPORT_DATA')}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <ExportDirectory
                    exportFolder={exportFolder}
                    changeExportDirectory={changeExportDirectory}
                    exportStage={exportStage}
                />
                <TotalFileCount totalFileCount={totalFileCount} />
            </DialogContent>
            <Divider />
            <ExportDynamicContent />
        </Dialog>
    );
}

function ExportDirectory({ exportFolder, changeExportDirectory, exportStage }) {
    return (
        <SpaceBetweenFlex minHeight={'40px'}>
            <Typography color="text.secondary">{t('DESTINATION')}</Typography>
            <>
                {!exportFolder ? (
                    <Button color={'accent'} onClick={changeExportDirectory}>
                        {t('SELECT_FOLDER')}
                    </Button>
                ) : (
                    <VerticallyCenteredFlex>
                        <Tooltip title={exportFolder}>
                            <ExportFolderPathContainer>
                                {exportFolder}
                            </ExportFolderPathContainer>
                        </Tooltip>
                        {exportStage === ExportStage.FINISHED ||
                        exportStage === ExportStage.INIT ? (
                            <ExportDirectoryOption
                                changeExportDirectory={changeExportDirectory}
                            />
                        ) : (
                            <Box sx={{ width: '48px' }} />
                        )}
                    </VerticallyCenteredFlex>
                )}
            </>
        </SpaceBetweenFlex>
    );
}

function TotalFileCount({ totalFileCount }) {
    return (
        <SpaceBetweenFlex minHeight={'40px'} pr={2}>
            <Typography color={'text.secondary'}>
                {t('TOTAL_FILE_COUNT')}{' '}
            </Typography>
            <Typography>{totalFileCount}</Typography>
        </SpaceBetweenFlex>
    );
}

function ExportDirectoryOption({ changeExportDirectory }) {
    return (
        <OverflowMenu
            triggerButtonProps={{
                sx: {
                    ml: 1,
                },
            }}
            ariaControls={'export-option'}
            triggerButtonIcon={<MoreHoriz />}>
            <OverflowMenuOption
                onClick={changeExportDirectory}
                startIcon={<FolderIcon />}>
                {t('CHANGE_FOLDER')}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
