import React from 'react';
import { Button, ProgressBar } from 'react-bootstrap';
import { ExportStage, ExportStats } from 'services/exportService';
import styled from 'styled-components';
import constants from 'utils/strings/constants';

export const ComfySpan = styled.span`
    word-spacing:1rem;
    color:#ddd;
`;

interface Props {
    show: boolean
    onHide: () => void
    exportFolder: string
    exportSize: string
    exportStage: ExportStage
    exportStats: ExportStats
    exportFiles: () => void;
    cancelExport: () => void
    pauseExport: () => void;
}
export default function ExportInProgress(props: Props) {
    return (
        <>
            <div style={{ marginBottom: '30px', padding: '0 5%', display: 'flex', alignItems: 'center', flexDirection: 'column' }}>
                <div style={{ marginBottom: '10px' }}>
                    <ComfySpan> {props.exportStats.current} / {props.exportStats.total} </ComfySpan> <span style={{ marginLeft: '10px' }}> files exported {props.exportStage === ExportStage.PAUSED && `(paused)`}</span>
                </div>
                <div style={{ width: '100%', marginBottom: '30px' }}>
                    <ProgressBar
                        now={Math.round(props.exportStats.current * 100 / props.exportStats.total)}
                        animated={!(props.exportStage === ExportStage.PAUSED)}
                        variant="upload-progress-bar"
                    />
                </div>
                <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                    {props.exportStage === ExportStage.PAUSED ?
                        <Button block variant={'outline-secondary'} onClick={props.exportFiles}>{constants.RESUME}</Button> :
                        <Button block variant={'outline-secondary'} onClick={props.pauseExport}>{constants.PAUSE}</Button>
                    }
                    <div style={{ width: '30px' }} />
                    <Button block variant={'outline-danger'} onClick={props.cancelExport}>{constants.CANCEL}</Button>
                </div>
            </div>
        </>
    );
}
