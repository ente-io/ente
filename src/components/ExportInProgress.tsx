import React from 'react';
import { Button, ProgressBar } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import InProgressIcon from './icons/InProgressIcon';
import MessageDialog from './MessageDialog';
import { Label, Row, Value } from './Container';
import { ExportState, ExportStats } from './ExportModal';

export const ComfySpan = styled.span`
    word-spacing:1rem;
    color:#ddd;
`;

interface Props {
    show: boolean
    onHide: () => void
    updateExportState: (newState: ExportState) => void;
    exportFolder: string
    exportSize: string
    exportState: ExportState
    exportStats: ExportStats
    exportFiles: () => void;
    cancelExport: () => void
}
export default function ExportInProgress(props: Props) {
    const pauseExport = () => {
        props.updateExportState(ExportState.PAUSED);
        props.cancelExport();
    };
    const cancelExport = () => {
        props.updateExportState(ExportState.FINISHED);
        props.cancelExport();
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
                <Row >
                    <Label width="40%">{constants.EXPORT_IN_PROGRESS}</Label> <Value width="60%"> <InProgressIcon /></Value>
                </Row>
                <Row>
                    <Label width="40%">{constants.DESTINATION}</Label>
                    <Value width="60%">
                        <span style={{ overflow: 'hidden', direction: 'rtl', height: '1.5rem', width: '90%', whiteSpace: 'nowrap' }}>
                            {props.exportFolder}
                        </span>
                    </Value>
                </Row>
                <Row>
                    <Label width="40%">{constants.TOTAL_EXPORT_SIZE} </Label><Value width="60%">24GB</Value>
                </Row>
            </div>
            <div style={{ marginBottom: '30px', padding: '0 5%', display: 'flex', alignItems: 'center', flexDirection: 'column' }}>
                <div style={{ marginBottom: '10px' }}>
                    <ComfySpan> {props.exportStats.current} / {props.exportStats.total} </ComfySpan> <span style={{ marginLeft: '10px' }}> files exported</span>
                </div>
                <div style={{ width: '100%', marginBottom: '30px' }}>
                    <ProgressBar
                        now={Math.round(props.exportStats.current * 100 / props.exportStats.total)}
                        animated
                        variant="upload-progress-bar"
                    />
                </div>
                <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                    {props.exportState === ExportState.PAUSED ?
                        <Button block variant={'outline-secondary'} onClick={props.exportFiles}>{constants.RESUME}</Button> :
                        <Button block variant={'outline-secondary'} onClick={pauseExport}>{constants.PAUSE}</Button>
                    }
                    <div style={{ width: '30px' }} />
                    <Button block variant={'outline-danger'} onClick={cancelExport}>{constants.CANCEL}</Button>
                </div>
            </div>
        </MessageDialog >
    );
}
