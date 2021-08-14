import React from 'react';
import { Button } from 'react-bootstrap';
import { ExportStats } from 'services/exportService';
import { formatDateTime } from 'utils/file';
import constants from 'utils/strings/constants';
import { Label, Row, Value } from './Container';
import { ComfySpan } from './ExportInProgress';

interface Props {
    show: boolean;
    onHide: () => void;
    exportFolder: string;
    exportSize: string;
    lastExportTime: number;
    exportStats: ExportStats;
    updateExportFolder: (newFolder: string) => void;
    exportFiles: () => void;
    retryFailed: () => void;
}

export default function ExportFinished(props: Props) {
    const totalFiles = props.exportStats.failed + props.exportStats.success;
    return (
        <>
            <div
                style={{
                    borderBottom: '1px solid #444',
                    marginBottom: '20px',
                    padding: '0 5%',
                }}>
                <Row>
                    <Label width="40%">{constants.LAST_EXPORT_TIME}</Label>
                    <Value width="60%">
                        {formatDateTime(props.lastExportTime)}
                    </Value>
                </Row>
                <Row>
                    <Label width="60%">
                        {constants.SUCCESSFULLY_EXPORTED_FILES}
                    </Label>
                    <Value width="35%">
                        <ComfySpan>
                            {props.exportStats.success} / {totalFiles}
                        </ComfySpan>
                    </Value>
                </Row>
                {props.exportStats.failed > 0 && (
                    <Row>
                        <Label width="60%">
                            {constants.FAILED_EXPORTED_FILES}
                        </Label>
                        <Value width="35%">
                            <ComfySpan>
                                {props.exportStats.failed} / {totalFiles}
                            </ComfySpan>
                        </Value>
                    </Row>
                )}
            </div>
            <div
                style={{
                    width: '100%',
                    display: 'flex',
                    justifyContent: 'space-around',
                }}>
                <Button
                    block
                    variant={'outline-secondary'}
                    onClick={props.onHide}>
                    {constants.CLOSE}
                </Button>
                <div style={{ width: '30px' }} />
                {props.exportStats.failed !== 0 ? (
                    <Button
                        block
                        variant={'outline-danger'}
                        onClick={props.retryFailed}>
                        {constants.RETRY_EXPORT_}
                    </Button>
                ) : (
                    <Button
                        block
                        variant={'outline-success'}
                        onClick={props.exportFiles}>
                        {constants.EXPORT_AGAIN}
                    </Button>
                )}
            </div>
        </>
    );
}
