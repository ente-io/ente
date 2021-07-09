import React, { useEffect, useState } from 'react';
import { Button } from 'react-bootstrap';
import exportService from 'services/exportService';
import styled from 'styled-components';
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

    &:hover{
        background-color:#444;
    }
    `;
export enum ExportStage {
    INIT,
    INPROGRESS,
    PAUSED,
    FINISHED
}

interface Props {
    show: boolean
    onHide: () => void
    usage: string
}
export interface ExportStats {
    current: number;
    total: number;
    failed: number;
}
export default function ExportModal(props: Props) {
    const [exportStage, setExportStage] = useState(ExportStage.INIT);
    const [exportFolder, setExportFolder] = useState(null);
    const [exportSize, setExportSize] = useState(null);
    const [exportStats, setExportStats] = useState<ExportStats>({ current: 0, total: 0, failed: 0 });
    const [lastExportTime, setLastExportTime] = useState(0);

    useEffect(() => {
        const exportInfo = getData(LS_KEYS.EXPORT);
        exportInfo?.state && setExportStage(exportInfo.state);
        exportInfo?.folder && setExportFolder(exportInfo.folder);
        exportInfo?.time && setLastExportTime(exportInfo.time);
        setExportSize(props.usage);
        exportService.ElectronAPIs.registerStopExportListener(stopExport);
        exportService.ElectronAPIs.registerPauseExportListener(pauseExport);
        exportService.ElectronAPIs.registerStartExportListener(startExport);
    }, []);

    useEffect(() => {
        if (exportStats.total !== 0 && exportStats.current === exportStats.total) {
            updateExportStage(ExportStage.FINISHED);
            updateExportTime(Date.now());
        }
    }, [exportStats]);

    useEffect(() => {
        setExportSize(props.usage);
    }, [props.usage]);

    const updateExportFolder = (newFolder) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), folder: newFolder });
    };
    const updateExportStage = (newState) => {
        setExportStage(newState);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), state: newState });
    };
    const updateExportTime = (newTime) => {
        setLastExportTime(newTime);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), time: newTime });
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
        setExportStats({ current: 0, total: 0, failed: 0 });
        exportService.exportFiles(setExportStats);
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

    const stopExport = () => {
        exportService.stopRunningExport();
        const lastExportTime = getData(LS_KEYS.EXPORT)?.time;
        if (!lastExportTime) {
            updateExportStage(ExportStage.INIT);
        } else {
            updateExportStage(ExportStage.FINISHED);
        }
    };
    const pauseExport = () => {
        updateExportStage(ExportStage.PAUSED);
        exportService.pauseRunningExport();
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
                        exportStats={exportStats}
                        exportFiles={startExport}
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
                                <FolderIconWrapper onClick={selectExportDirectory} >
                                    <FolderIcon />
                                </FolderIconWrapper>
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
