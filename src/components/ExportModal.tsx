import React, { useEffect, useState } from 'react';
import exportService from 'services/exportService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';

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
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
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
        if (exportStats.current === exportStats.total) {
            updateExportState(ExportState.FINISHED);
            updateExportTime(Date.now());
        }
    }, [exportStats]);
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
    switch (exportState) {
        case ExportState.INIT:
            return (
                <ExportInit {...props}
                    exportFolder={exportFolder}
                    exportSize={exportSize}
                    updateExportFolder={updateExportFolder}
                    exportFiles={startExport}
                    updateExportState={updateExportState}
                />
            );
        case ExportState.INPROGRESS:
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
    }
}
