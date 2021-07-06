import React from 'react';
import { Button } from 'react-bootstrap';
import { formatDateTime } from 'utils/file';
import constants from 'utils/strings/constants';
import { Label, Row, Value } from './Container';
import { ComfySpan } from './ExportInProgress';
import FolderIcon from './icons/FolderIcon';
import InProgressIcon from './icons/InProgressIcon';
import MessageDialog from './MessageDialog';

export default function ExportInit(props) {
    return (
        <MessageDialog
            show={props.show}
            onHide={props.onHide}
            size="lg"
            attributes={{
                title: constants.EXPORT_DATA,
            }}
        >
            <div style={{ borderBottom: '1px solid #444', marginBottom: '20px', padding: '0 5%' }}>
                <Row>
                    <Label>{constants.DESTINATION} </Label>
                    <Value>
                        Folder Name
                        <div onClick={null} style={{ marginLeft: '5px', cursor: 'pointer' }}><FolderIcon /></div>
                    </Value>
                </Row>
                <Row>
                    <Label>{constants.TOTAL_EXPORT_SIZE} </Label><Value>24GB</Value>
                </Row>
            </div>
            <div style={{ borderBottom: '1px solid #444', marginBottom: '20px', padding: '0 5%' }}>
                <Row>
                    <Label width="40%">{constants.LAST_EXPORT_TIME}</Label>
                    <Value width="60%">{formatDateTime(Date.now())}</Value>
                </Row>
                <Row>
                    <Label width="60%">{constants.SUCCESSFULLY_EXPORTED_FILES}</Label>
                    <Value width="35%"><ComfySpan>80 / 100</ComfySpan></Value>
                </Row>
                <Row>
                    <Label width="60%">{constants.FAILED_EXPORTED_FILES}</Label>
                    <Value width="35%">
                        <ComfySpan>20 / 100</ComfySpan>
                    </Value>
                    <Value width="5%">
                        <InProgressIcon disabled />
                    </Value>
                </Row>
            </div>
            <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                <Button block variant={'outline-secondary'}>{constants.CLOSE}</Button>
                <div style={{ width: '30px' }} />
                <Button block variant={'outline-success'}>{constants.EXPORT}</Button>
            </div>
        </MessageDialog >
    );
}
