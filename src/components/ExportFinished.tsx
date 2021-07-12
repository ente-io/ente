import React from 'react';
import { Button } from 'react-bootstrap';
import { formatDateTime } from 'utils/file';
import constants from 'utils/strings/constants';
import { Label, Row, Value } from './Container';
import { ComfySpan } from './ExportInProgress';
import { ExportStats } from './ExportModal';
import InProgressIcon from './icons/InProgressIcon';


interface Props {
    show: boolean
    onHide: () => void
    exportFolder: string
    exportSize: string
    lastExportTime: number
    exportStats: ExportStats
    updateExportFolder: (newFolder: string) => void;
    exportFiles: () => void;
    retryFailed: () => void;
}

export default function ExportFinished(props: Props) {
    return (
        <>
            <div style={{ borderBottom: '1px solid #444', marginBottom: '20px', padding: '0 5%' }}>
                <Row>
                    <Label width="40%">{constants.LAST_EXPORT_TIME}</Label>
                    <Value width="60%">{formatDateTime(props.lastExportTime)}</Value>
                </Row>
                <Row>
                    <Label width="60%">{constants.SUCCESSFULLY_EXPORTED_FILES}</Label>
                    <Value width="35%"><ComfySpan>{props.exportStats.total - props.exportStats.failed} / {props.exportStats.total}</ComfySpan></Value>
                </Row>
                <Row>
                    <Label width="60%">{constants.FAILED_EXPORTED_FILES}</Label>
                    <Value width="35%">
                        <ComfySpan>{props.exportStats.failed} / {props.exportStats.total}</ComfySpan>
                    </Value>
                    {props.exportStats.failed !== 0 &&
                        <Value width="5%">
                            <InProgressIcon disabled onClick={props.retryFailed} />
                        </Value>
                    }
                </Row>
            </div>
            <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                <Button block variant={'outline-secondary'} onClick={props.onHide}>{constants.CLOSE}</Button>
                <div style={{ width: '30px' }} />
                <Button block variant={'outline-success'} onClick={props.exportFiles}>{constants.EXPORT_AGAIN}</Button>
            </div>
        </>
    );
}
