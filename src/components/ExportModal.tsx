import isElectron from 'is-electron';
import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import exportService, { ExportProgress, ExportRecord, ExportStage, ExportStats } from 'services/exportService';
import styled from 'styled-components';
import { sleep } from 'utils/common';
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
        const main = async () => {
            const exportInfo = await exportService.getExportRecord();
            setExportStage(exportInfo?.stage ?? ExportStage.INIT);
            setLastExportTime(exportInfo?.lastAttemptTimestamp);
            setExportProgress(exportInfo?.progress ?? { current: 0, total: 0 });
            console.log({ success: exportInfo?.exportedFiles?.length ?? 0, failed: exportInfo?.failedFiles?.length ?? 0 });
            setExportStats({ success: exportInfo?.exportedFiles?.length ?? 0, failed: exportInfo?.failedFiles?.length ?? 0 });
            if (exportInfo?.stage === ExportStage.INPROGRESS) {
                startExport();
            }
        };
        main();
    }, [exportFolder]);


    useEffect(() => {
        setExportSize(props.usage);
    }, [props.usage]);

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

    const startExport = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            const folderSelected = await selectExportDirectory();
            if (!folderSelected) {
                // no-op as select folder aborted
                return;
            }
        }
        updateExportStage(ExportStage.INPROGRESS);
        updateExportProgress({ current: 0, total: 0 });

        const { paused } = await exportService.exportFiles(updateExportProgress);

        if (!paused) {
            updateExportStage(ExportStage.FINISHED);
            await sleep(100);
            updateExportTime(Date.now());
        }
    };
    const retryFailedExport = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            const folderSelected = await selectExportDirectory();
            if (!folderSelected) {
                // no-op as select folder aborted
                return;
            }
        }
        updateExportStage(ExportStage.INPROGRESS);
        updateExportProgress({ current: 0, total: 0 });
        const finished = await exportService.retryFailedFiles(updateExportProgress);
        if (finished) {
            updateExportStage(ExportStage.FINISHED);
            await sleep(100);
            updateExportTime(Date.now());
        }
    };

    const resumeExport = async () => {
        const exportFolder = getData(LS_KEYS.EXPORT)?.folder;
        if (!exportFolder) {
            const folderSelected = await selectExportDirectory();
            if (!folderSelected) {
                // no-op as select folder aborted
                return;
            }
        }
        const exportRecord = await exportService.getExportRecord();
        if (exportRecord.stage !== ExportStage.PAUSED) {
            // export not paused
            return;
        }
        const pausedStageProgress = exportRecord.progress;
        updateExportStage(ExportStage.INPROGRESS);
        updateExportProgress(pausedStageProgress);
        const updateExportStatsWithOffset = ((progress: ExportProgress) => updateExportProgress(
            {
                current: pausedStageProgress.current + progress.current,
                total: pausedStageProgress.current + progress.total,
            },
        ));
        const finished = await exportService.exportFiles(updateExportStatsWithOffset);

        if (finished) {
            updateExportStage(ExportStage.FINISHED);
            await sleep(100);
            updateExportTime(Date.now());
        }
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

    const revertExportStatsToLastExport = async (exportRecord: ExportRecord) => {
        const failed = exportRecord?.failedFiles?.length ?? 0;
        const success = exportRecord?.exportedFiles?.length ?? 0;
        setExportStats({ failed, success });
    };

    const stopExport = async () => {
        exportService.stopRunningExport();
        const exportRecord = await exportService.getExportRecord();
        await revertExportStatsToLastExport(exportRecord);
        if (!exportRecord.lastAttemptTimestamp) {
            updateExportStage(ExportStage.INIT);
        } else {
            updateExportStage(ExportStage.FINISHED);
        }
    };
    const pauseExport = () => {
        updateExportStage(ExportStage.PAUSED);
        exportService.pauseRunningExport();
    };
    const retryFailed = async () => {
        updateExportStage(ExportStage.INPROGRESS);
        await sleep(100);
        updateExportProgress({ current: 0, total: exportStats.failed });
        await exportService.retryFailedFiles(updateExportProgress);
        updateExportStage(ExportStage.FINISHED);
        await sleep(100);
        updateExportTime(Date.now());
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
                        retryFailed={retryFailed}
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
                            (<Button variant={'outline-success'} onClick={selectExportDirectory}>{constants.SELECT_FOLDER}</Button>) :
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
