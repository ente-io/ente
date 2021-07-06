import React from 'react';
import { Button, ProgressBar } from 'react-bootstrap';
import styled from 'styled-components';
import constants from 'utils/strings/constants';
import InProgressIcon from './icons/InProgressIcon';
import MessageDialog from './MessageDialog';
import { Label, Row, Value } from './Container';

const ComfySpan = styled.span`
    margin:0 0.2rem;
    color:#ddd;
`;
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
                    <Label>{constants.EXPORT_IN_PROGRESS}</Label> <Value> <InProgressIcon /></Value>
                </Row>
                <Row>
                    <Label>{constants.DESTINATION}</Label> <Value>Folder Name</Value>
                </Row>
                <Row>
                    <Label>{constants.TOTAL_EXPORT_SIZE} </Label><Value>24GB</Value>
                </Row>
            </div>
            <div style={{ marginBottom: '30px', padding: '0 5%', display: 'flex', alignItems: 'center', flexDirection: 'column' }}>
                <div style={{ marginBottom: '10px' }}>
                    <ComfySpan> 10 </ComfySpan><ComfySpan> / </ComfySpan><ComfySpan> 24 </ComfySpan> <span style={{ marginLeft: '10px' }}> files exported</span>
                </div>
                <div style={{ width: '100%', marginBottom: '30px' }}>
                    <ProgressBar
                        now={40}
                        animated
                        variant="upload-progress-bar"
                    />
                </div>
                <div style={{ width: '100%', display: 'flex', justifyContent: 'space-around' }}>
                    <Button block variant={'outline-secondary'}>{constants.PAUSE}</Button>
                    <div style={{ width: '30px' }} />
                    <Button block variant={'outline-danger'}>{constants.CANCEL}</Button>
                </div>
            </div>
        </MessageDialog >
    );
}
