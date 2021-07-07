import React from 'react';
import { Button } from 'react-bootstrap';
import exportService from 'services/exportService';
import { formatDateTime } from 'utils/file';
import constants from 'utils/strings/constants';
import { Label, Row, Value } from './Container';
import { ComfySpan } from './ExportInProgress';
import { ExportStats } from './ExportModal';
import FolderIcon from './icons/FolderIcon';
import InProgressIcon from './icons/InProgressIcon';
import MessageDialog from './MessageDialog';


interface Props {
    show: boolean
    onHide: () => void
    exportFolder: string
    exportSize: string
    lastExportTime: number
    exportStats: ExportStats
    updateExportFolder: (newFolder: string) => void;
    exportFiles: () => void
}

export default function ExportFinished(props: Props) {
    const selectNewDirectory = async () => {
        const newFolder = await exportService.selectExportDirectory();
        newFolder && props.updateExportFolder(newFolder);
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
                        {!props.exportFolder ?
                            (<Button variant={'outline-success'} onClick={selectNewDirectory}>{constants.SELECT_FOLDER}</Button>) :
                            (<>
                                <span style={{ overflow: 'hidden', direction: 'rtl', height: '1.5rem', width: '90%', whiteSpace: 'nowrap' }}>
                                    {props.exportFolder}
                                </span>
                                <div onClick={selectNewDirectory} style={{ width: '10%', marginLeft: '5px', cursor: 'pointer' }}>
                                    <FolderIcon />
                                </div>
                            </>)
                        }
                    </Value>
                </Row>
                <Row>
                    <Label width="40%">{constants.TOTAL_EXPORT_SIZE} </Label><Value width="60%">{props.exportSize} GB</Value>
                </Row>
            </div>
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
                            <InProgressIcon disabled />
                        </Value>
                    }
                </Row>
            </div>
            <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                <Button block variant={'outline-secondary'} onClick={props.onHide}>{constants.CLOSE}</Button>
                <div style={{ width: '30px' }} />
                <Button block variant={'outline-success'} onClick={props.exportFiles}>{constants.EXPORT}</Button>
            </div>
        </MessageDialog >
    );
}
