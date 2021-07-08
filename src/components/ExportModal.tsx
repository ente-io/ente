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
export enum ExportState {
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
    const [exportState, setExportState] = useState(ExportState.INIT);
    const [exportFolder, setExportFolder] = useState(null);
    const [exportSize, setExportSize] = useState(null);
    const [exportStats, setExportStats] = useState<ExportStats>({ current: 0, total: 0, failed: 0 });
    const [lastExportTime, setLastExportTime] = useState(0);

    useEffect(() => {
        const exportInfo = getData(LS_KEYS.EXPORT);
        exportInfo?.state && setExportState(exportInfo.state);
        exportInfo?.folder && setExportFolder(exportInfo.folder);
        exportInfo?.time && setLastExportTime(exportInfo.time);
        setExportSize(props.usage);
    }, []);

    useEffect(() => {
        if (exportStats.total !== 0 && exportStats.current === exportStats.total) {
            updateExportState(ExportState.FINISHED);
            updateExportTime(Date.now());
        }
    }, [exportStats]);

    useEffect(() => {
        setExportSize(props.usage);
        console.log(props.usage);
    }, [props.usage]);

    const updateExportFolder = (newFolder) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), folder: newFolder });
    };
    const updateExportState = (newState) => {
        setExportState(newState);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), state: newState });
    };
    const updateExportTime = (newTime) => {
        setLastExportTime(newTime);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), time: newTime });
    };

    const startExport = () => {
        updateExportState(ExportState.INPROGRESS);
        setExportStats({ current: 0, total: 0, failed: 0 });
        exportService.exportFiles(setExportStats);
    };

    const selectExportDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        newFolder && updateExportFolder(newFolder);
    };

    const ExportDynamicState = () => {
        switch (exportState) {
            case ExportState.INIT:
                return (
                    <ExportInit {...props}
                        exportFolder={exportFolder}
                        exportSize={exportSize}
                        updateExportFolder={updateExportFolder}
                        exportFiles={startExport}
                        updateExportState={updateExportState}
                        selectExportDirectory={selectExportDirectory}
                    />
                );
            case ExportState.INPROGRESS:
            case ExportState.PAUSED:
                return (
                    <ExportInProgress {...props}
                        exportFolder={exportFolder}
                        exportSize={exportSize}
                        exportState={exportState}
                        updateExportState={updateExportState}
                        exportStats={exportStats}
                        exportFiles={startExport}
                        cancelExport={exportService.cancelExport}
                    />
                );
            case ExportState.FINISHED:
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
