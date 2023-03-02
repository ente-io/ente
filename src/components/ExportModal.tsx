import isElectron from 'is-electron';
import React, { useEffect, useMemo, useState, useContext } from 'react';
import exportService from 'services/exportService';
import { ExportProgress, ExportStats } from 'types/export';
import { getLocalFiles } from 'services/fileService';
import { User } from 'types/user';
import {
    Button,
    Dialog,
    DialogContent,
    Divider,
    Stack,
    styled,
    Tooltip,
} from '@mui/material';
import { sleep } from 'utils/common';
import { getExportRecordFileUID } from 'utils/export';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import { FlexWrapper, Label, Value } from './Container';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';
import FolderIcon from '@mui/icons-material/Folder';
import { ExportStage, ExportType } from 'constants/export';
import EnteSpinner from './EnteSpinner';
import DialogTitleWithCloseButton from './DialogBox/TitleWithCloseButton';
import MoreHoriz from '@mui/icons-material/MoreHoriz';
import OverflowMenu from './OverflowMenu/menu';
import { OverflowMenuOption } from './OverflowMenu/option';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { CustomError } from 'utils/error';
import { getLocalUserDetails } from 'utils/user';
import { AppContext } from 'pages/_app';
import { getExportDirectoryDoesNotExistMessage } from 'utils/ui';

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
    const userDetails = useMemo(() => getLocalUserDetails(), []);
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState('');
    const [exportSize, setExportSize] = useState('');
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

            exportService.electronAPIs.registerStopExportListener(
                stopExportHandler
            );
            exportService.electronAPIs.registerPauseExportListener(
                pauseExportHandler
            );
            exportService.electronAPIs.registerResumeExportListener(
                resumeExportHandler
            );
            exportService.electronAPIs.registerRetryFailedExportListener(
                retryFailedExportHandler
            );
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
                setExportProgress(
                    exportInfo?.progress ?? { current: 0, total: 0 }
                );
                setExportStats({
                    success: exportInfo?.exportedFiles?.length ?? 0,
                    failed: exportInfo?.failedFiles?.length ?? 0,
                });
                if (exportInfo?.stage === ExportStage.INPROGRESS) {
                    await resumeExport();
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
        const main = async () => {
            const user: User = getData(LS_KEYS.USER);
            if (exportStage === ExportStage.FINISHED) {
                try {
                    const localFiles = await getLocalFiles();
                    const userPersonalFiles = localFiles.filter(
                        (file) => file.ownerID === user?.id
                    );
                    const exportRecord = await exportService.getExportRecord();
                    const exportedFileCnt = exportRecord.exportedFiles?.length;
                    const failedFilesCnt = exportRecord.failedFiles?.length;
                    const syncedFilesCnt = userPersonalFiles.length;
                    if (syncedFilesCnt > exportedFileCnt + failedFilesCnt) {
                        await updateExportProgress({
                            current: exportedFileCnt + failedFilesCnt,
                            total: syncedFilesCnt,
                        });
                        const exportFileUIDs = new Set([
                            ...exportRecord.exportedFiles,
                            ...exportRecord.failedFiles,
                        ]);
                        const unExportedFiles = userPersonalFiles.filter(
                            (file) =>
                                !exportFileUIDs.has(
                                    getExportRecordFileUID(file)
                                )
                        );
                        await exportService.addFilesQueuedRecord(
                            exportFolder,
                            unExportedFiles
                        );
                        await updateExportStage(ExportStage.PAUSED);
                    }
                } catch (e) {
                    setExportStage(ExportStage.INIT);
                    logError(e, 'error while updating exportModal on reopen');
                }
            }
        };
        void main();
    }, [props.show]);

    useEffect(() => {
        setExportSize(convertBytesToHumanReadable(userDetails?.usage));
    }, [userDetails]);

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

    const updateExportProgress = async (newProgress: ExportProgress) => {
        setExportProgress(newProgress);
        await exportService.updateExportRecord({ progress: newProgress });
    };

    // ======================
    // HELPER FUNCTIONS
    // =========================

    const preExportRun = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            await selectExportDirectory();
        }
        const exportFolderExists = exportService.exists(exportFolder);
        if (!exportFolderExists) {
            appContext.setDialogMessage(
                getExportDirectoryDoesNotExistMessage(selectExportDirectory)
            );
            return;
        }
        await updateExportStage(ExportStage.INPROGRESS);
        await sleep(100);
    };
    const postExportRun = async (exportResult?: { paused?: boolean }) => {
        if (!exportResult?.paused) {
            await updateExportStage(ExportStage.FINISHED);
            await sleep(100);
            await updateExportTime(Date.now());
            await syncExportStatsWithRecord();
        }
    };

    const selectExportDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        if (newFolder) {
            updateExportFolder(newFolder);
        } else {
            throw Error(CustomError.REQUEST_CANCELLED);
        }
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

    const startExport = async () => {
        try {
            await preExportRun();
            await updateExportProgress({ current: 0, total: 0 });
            const exportResult = await exportService.exportFiles(
                updateExportProgress,
                ExportType.NEW
            );
            await postExportRun(exportResult);
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'startExport failed');
            }
        }
    };

    const stopExport = async () => {
        try {
            exportService.stopRunningExport();
            await postExportRun();
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'stopExport failed');
            }
        }
    };

    const pauseExport = async () => {
        try {
            await updateExportStage(ExportStage.PAUSED);
            exportService.pauseRunningExport();
            await postExportRun({ paused: true });
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'pauseExport failed');
            }
        }
    };

    const resumeExport = async () => {
        try {
            const exportRecord = await exportService.getExportRecord();
            await preExportRun();

            const pausedStageProgress = exportRecord.progress;
            setExportProgress(pausedStageProgress);

            const updateExportStatsWithOffset = (progress: ExportProgress) =>
                updateExportProgress({
                    current: pausedStageProgress.current + progress.current,
                    total: pausedStageProgress.current + progress.total,
                });
            const exportResult = await exportService.exportFiles(
                updateExportStatsWithOffset,
                ExportType.PENDING
            );

            await postExportRun(exportResult);
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'resumeExport failed');
            }
        }
    };

    const retryFailedExport = async () => {
        try {
            await preExportRun();
            await updateExportProgress({
                current: 0,
                total: exportStats.failed,
            });

            const exportResult = await exportService.exportFiles(
                updateExportProgress,
                ExportType.RETRY_FAILED
            );
            await postExportRun(exportResult);
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'retryFailedExport failed');
            }
        }
    };

    const startExportHandler = () => {
        void startExport();
    };
    const stopExportHandler = () => {
        void stopExport();
    };
    const pauseExportHandler = () => {
        void pauseExport();
    };
    const resumeExportHandler = () => {
        void resumeExport();
    };
    const retryFailedExportHandler = () => {
        void retryFailedExport();
    };

    const ExportDynamicContent = () => {
        switch (exportStage) {
            case ExportStage.INIT:
                return <ExportInit startExport={startExportHandler} />;

            case ExportStage.INPROGRESS:
            case ExportStage.PAUSED:
                return (
                    <ExportInProgress
                        exportStage={exportStage}
                        exportProgress={exportProgress}
                        resumeExport={resumeExportHandler}
                        cancelExport={stopExportHandler}
                        pauseExport={pauseExportHandler}
                    />
                );
            case ExportStage.FINISHED:
                return (
                    <ExportFinished
                        onHide={props.onHide}
                        lastExportTime={lastExportTime}
                        exportStats={exportStats}
                        exportFiles={startExportHandler}
                        retryFailed={retryFailedExportHandler}
                    />
                );

            default:
                return <></>;
        }
    };

    return (
        <Dialog open={props.show} onClose={props.onHide} maxWidth="xs">
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {constants.EXPORT_DATA}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Stack spacing={2}>
                    <ExportDirectory
                        exportFolder={exportFolder}
                        selectExportDirectory={selectExportDirectory}
                        exportStage={exportStage}
                    />
                    <ExportSize exportSize={exportSize} />
                </Stack>
            </DialogContent>
            <Divider />
            <ExportDynamicContent />
        </Dialog>
    );
}

function ExportDirectory({ exportFolder, selectExportDirectory, exportStage }) {
    return (
        <FlexWrapper>
            <Label width="30%">{constants.DESTINATION}</Label>
            <Value width="70%">
                {!exportFolder ? (
                    <Button color={'accent'} onClick={selectExportDirectory}>
                        {constants.SELECT_FOLDER}
                    </Button>
                ) : (
                    <>
                        <Tooltip title={exportFolder}>
                            <ExportFolderPathContainer>
                                {exportFolder}
                            </ExportFolderPathContainer>
                        </Tooltip>
                        {(exportStage === ExportStage.FINISHED ||
                            exportStage === ExportStage.INIT) && (
                            <ExportDirectoryOption
                                selectExportDirectory={selectExportDirectory}
                            />
                        )}
                    </>
                )}
            </Value>
        </FlexWrapper>
    );
}

function ExportSize({ exportSize }) {
    return (
        <FlexWrapper>
            <Label width="30%">{constants.EXPORT_SIZE} </Label>
            <Value width="70%">
                {exportSize ? `${exportSize}` : <EnteSpinner />}
            </Value>
        </FlexWrapper>
    );
}

function ExportDirectoryOption({ selectExportDirectory }) {
    const handleClick = () => {
        try {
            selectExportDirectory();
        } catch (e) {
            if (e.message !== CustomError.REQUEST_CANCELLED) {
                logError(e, 'startExport failed');
            }
        }
    };
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
                onClick={handleClick}
                startIcon={<FolderIcon />}>
                {constants.CHANGE_FOLDER}
            </OverflowMenuOption>
        </OverflowMenu>
    );
}
