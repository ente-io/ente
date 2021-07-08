import { DeadCenter } from 'pages/gallery';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import { ExportStage } from './ExportModal';

interface Props {
    show: boolean
    onHide: () => void
    updateExportFolder: (newFolder: string) => void;
    updateExportStage: (newState: ExportStage) => void;
    exportFolder: string
    exportFiles: () => void
    exportSize: string;
    selectExportDirectory: () => void
}
export default function ExportInit(props: Props) {
    const startExport = async () => {
        if (!props.exportFolder) {
            await props.selectExportDirectory();
        }
        props.exportFiles();
        props.updateExportStage(ExportStage.INPROGRESS);
    };
    return (
        <>
            <DeadCenter >
                <Button
                    variant="outline-success"
                    size="lg"
                    style={{
                        padding: '6px 3em',
                        margin: '0 20px',
                        marginBottom: '20px',
                        flex: 1,
                        whiteSpace: 'nowrap',
                    }}
                    onClick={startExport}
                >{constants.START}</Button>
            </DeadCenter>
        </>
    );
}
