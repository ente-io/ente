import React, { useEffect, useState } from 'react';
import exportService from 'services/exportService';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import ExportFinished from './ExportFinished';
import ExportInit from './ExportInit';
import ExportInProgress from './ExportInProgress';

export enum ExportState {
    INIT,
    INPROGRESS,
    FINISHED
}

interface Props {
    show: boolean
    onHide: () => void
    usage: number
}
export default function ExportModal(props: Props) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [exportState, setExportState] = useState(ExportState.INIT);
    const [exportFolder, setExportFolder] = useState(null);
    const [exportSize, setExportSize] = useState(null);
    useEffect(() => {
        const exportInfo = getData(LS_KEYS.EXPORT);
        exportInfo?.state && setExportState(exportInfo.state);
        exportInfo?.folder && setExportFolder(exportInfo.folder);
        setExportSize(props.usage);
    }, []);

    const updateExportFolder = (newFolder) => {
        setExportFolder(newFolder);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), folder: newFolder });
    };
    const updateExportState = (newState) => {
        setExportState(newState);
        setData(LS_KEYS.EXPORT, { ...getData(LS_KEYS.EXPORT), satte: newState });
    };
    switch (exportState) {
        case ExportState.INIT:
            return (
                <ExportInit {...props} exportFolder={exportFolder} exportSize={exportSize} updateExportFolder={updateExportFolder} exportFiles={() => exportService.exportFiles()} updateExportState={updateExportState} />
            );
        case ExportState.INPROGRESS:
            return (
                <ExportInProgress {...props} />
            );
        case ExportState.FINISHED:
            return (
                <ExportFinished {...props} />
            );
    }
}
