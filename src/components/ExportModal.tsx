import isElectron from 'is-electron';
import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import exportService, { ExportProgress, ExportStage, ExportStats, ExportType } from 'services/exportService';
import { getLocalFiles } from 'services/fileService';
import styled from 'styled-components';
import { sleep } from 'utils/common';
import { getFileUID } from 'utils/export';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import { Label, Row, Value } from './Container';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';
import FolderIcon from './icons/FolderIcon';
import InProgressIcon from './icons/InProgressIcon';
import MessageDialog from './MessageDialog';

const FolderIconWrapper = styled.div`
    width: 15%;
    margin-left: 10px; 
    cursor: pointer; 
    padding: 3px;
    border: 1px solid #444;
    border-radius:15%;
    &:hover{
        background-color:#444;
    }
    `;

interface Props {
    show: boolean
    onHide: () => void
    usage: string
}
export default function ExportModal(props: Props) {
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState('');
    const [exportSize, setExportSize] = useState('');
    const [exportProgress, setExportProgress] = useState<ExportProgress>({ current: 0, total: 0 });
    const [exportStats, setExportStats] = useState<ExportStats>({ failed: 0, success: 0 });
    const [lastExportTime, setLastExportTime] = useState(0);

    // ====================
    // SIDE EFFECTS
    // ====================
    useEffect(() => {
        if (!isElectron()) {
            return;
        }
        setExportFolder(getData(LS_KEYS.EXPORT)?.folder);

        exportService.ElectronAPIs.registerStopExportListener(stopExport);
        exportService.ElectronAPIs.registerPauseExportListener(pauseExport);
        exportService.ElectronAPIs.registerResumeExportListener(resumeExport);
        exportService.ElectronAPIs.registerRetryFailedExportListener(retryFailedExport);
    }, []);

    useEffect(() => {
        if (!exportFolder) {
            return;
        }
        const main = async () => {
            const exportInfo = await exportService.getExportRecord();
            setExportStage(exportInfo?.stage ?? ExportStage.INIT);
            setLastExportTime(exportInfo?.lastAttemptTimestamp);
            setExportProgress(exportInfo?.progress ?? { current: 0, total: 0 });
            setExportStats({ success: exportInfo?.exportedFiles?.length ?? 0, failed: exportInfo?.failedFiles?.length ?? 0 });
            if (exportInfo?.stage === ExportStage.INPROGRESS) {
                resumeExport();
            }
        };
        main();
    }, [exportFolder]);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            if (exportStage === ExportStage.FINISHED) {
                const localFiles = await getLocalFiles();
                const exportRecord = await exportService.getExportRecord();
                const exportedFileCnt = exportRecord.exportedFiles.length;
                const failedFilesCnt = exportRecord.failedFiles.length;
                const syncedFilesCnt = localFiles.length;
                if (syncedFilesCnt > exportedFileCnt + failedFilesCnt) {
                    updateExportProgress({ current: exportedFileCnt + failedFilesCnt, total: syncedFilesCnt });
                    const exportFileUIDs = new Set([...exportRecord.exportedFiles, ...exportRecord.failedFiles]);
                    const unExportedFiles = localFiles.filter((file) => !exportFileUIDs.has(getFileUID(file)));
                    console.log(exportedFileCnt + failedFilesCnt + unExportedFiles.length, syncedFilesCnt);
                    exportService.addFilesQueuedRecord(exportFolder, unExportedFiles);
                    updateExportStage(ExportStage.PAUSED);
                }
            }
        };
        main();
    }, [props.show]);


    useEffect(() => {
        setExportSize(props.usage);
    }, [props.usage]);

    // =============
    // STATE UPDATERS
    // ==============
    const updateExportFolder = (newFolder: string) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { folder: newFolder });
    };

    const updateExportStage = (newStage: ExportStage) => {
        setExportStage(newStage);
        exportService.updateExportRecord({ stage: newStage });
    };

    const updateExportTime = (newTime: number) => {
        setLastExportTime(newTime);
        exportService.updateExportRecord({ time: newTime });
    };

    const updateExportProgress = (newProgress: ExportProgress) => {
        setExportProgress(newProgress);
        exportService.updateExportRecord({ progress: newProgress });
    };

    // ======================
    // HELPER FUNCTIONS
    // =========================

    const preExportRun = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            const folderSelected = await selectExportDirectory();
            if (!folderSelected) {
                // no-op as select folder aborted
                return;
            }
        }
        updateExportStage(ExportStage.INPROGRESS);
        await sleep(100);
    };
    const postExportRun = async (paused: Boolean) => {
        if (!paused) {
            updateExportStage(ExportStage.FINISHED);
            await sleep(100);
            updateExportTime(Date.now());
            syncExportStatsWithReport();
        }
    };
    const startExport = async () => {
        await preExportRun();
        updateExportProgress({ current: 0, total: 0 });
        const { paused } = await exportService.exportFiles(updateExportProgress, ExportType.NEW);
        await postExportRun(paused);
    };

    const stopExport = async () => {
        exportService.stopRunningExport();
        postExportRun(false);
    };

    const pauseExport = () => {
        updateExportStage(ExportStage.PAUSED);
        exportService.pauseRunningExport();
        postExportRun(true);
    };

    const resumeExport = async () => {
        const exportRecord = await exportService.getExportRecord();
        await preExportRun();

        const pausedStageProgress = exportRecord.progress;
        setExportProgress(pausedStageProgress);

        const updateExportStatsWithOffset = ((progress: ExportProgress) => updateExportProgress(
            {
                current: pausedStageProgress.current + progress.current,
                total: pausedStageProgress.current + progress.total,
            },
        ));
        const { paused } = await exportService.exportFiles(updateExportStatsWithOffset, ExportType.PENDING);

        await postExportRun(paused);
    };

    const retryFailedExport = async () => {
        await preExportRun();
        updateExportProgress({ current: 0, total: exportStats.failed });

        const { paused } = await exportService.exportFiles(updateExportProgress, ExportType.RETRY_FAILED);
        await postExportRun(paused);
    };

    const syncExportStatsWithReport = async () => {
        const exportRecord = await exportService.getExportRecord();
        const failed = exportRecord?.failedFiles?.length ?? 0;
        const success = exportRecord?.exportedFiles?.length ?? 0;
        setExportStats({ failed, success });
    };

    const selectExportDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        if (newFolder) {
            updateExportFolder(newFolder);
            return true;
        } else {
            return false;
        }
    };

    const ExportDynamicState = () => {
        switch (exportStage) {
            case ExportStage.INIT:
                return (
                    <ExportInit {...props}
                        exportFolder={exportFolder}
                        exportSize={exportSize}
                        updateExportFolder={updateExportFolder}
                        startExport={startExport}
                        selectExportDirectory={selectExportDirectory}
                    />
                );
            case ExportStage.INPROGRESS:
            case ExportStage.PAUSED:
                return (
                    <ExportInProgress {...props}
                        exportFolder={exportFolder}
                        exportSize={exportSize}
                        exportStage={exportStage}
                        exportProgress={exportProgress}
                        resumeExport={resumeExport}
                        cancelExport={stopExport}
                        pauseExport={pauseExport}
                    />
                );
            case ExportStage.FINISHED:
                return (
                    <ExportFinished
                        {...props}
                        exportFolder={exportFolder}
                        exportSize={exportSize}
                        updateExportFolder={updateExportFolder}
                        lastExportTime={lastExportTime}
                        exportStats={exportStats}
                        exportFiles={startExport}
                        retryFailed={retryFailedExport}
                    />
                );

            default: return (<></>);
        }
    };

    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            attributes={{
                title: constants.EXPORT_DATA,
            }}
        >
            <div style={{ borderBottom: '1px solid #444', marginBottom: '20px', padding: '0 5%' }}>
                <Row>
                    <Label width="40%">{constants.DESTINATION}</Label>
                    <Value width="60%">
                        {!exportFolder ?
                            (<Button variant={'outline-success'} size={'sm'} onClick={selectExportDirectory}>{constants.SELECT_FOLDER}</Button>) :
                            (<>
                                <span style={{ overflow: 'hidden', direction: 'rtl', height: '1.5rem', width: '90%', whiteSpace: 'nowrap' }}>
                                    {exportFolder}
                                </span>
                                {(exportStage === ExportStage.FINISHED || exportStage === ExportStage.INIT) && (
                                    <FolderIconWrapper onClick={selectExportDirectory} >
                                        <FolderIcon />
                                    </FolderIconWrapper>
                                )}
                            </>)
                        }
                    </Value>
                </Row>
                <Row>
                    <Label width="40%">{constants.TOTAL_EXPORT_SIZE} </Label><Value width="60%">{exportSize ? `${exportSize} GB` : <InProgressIcon />}</Value>
                </Row>
            </div>
            <ExportDynamicState />
        </MessageDialog >
    );
}
