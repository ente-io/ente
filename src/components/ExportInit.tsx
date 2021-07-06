import { DeadCenter } from 'pages/gallery';
import React from 'react';
import { Button } from 'react-bootstrap';
import constants from 'utils/strings/constants';
import MessageDialog from './MessageDialog';
import { Row, Label, Value } from './Container';

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
                    <Label>{constants.DESTINATION}</Label> <Value><Button variant={'outline-success'} onClick={null}>{constants.SELECT_FOLDER}</Button></Value>
                </Row>
                <Row>
                    <Label>{constants.TOTAL_EXPORT_SIZE} </Label><Value>24GB</Value>
                </Row>
            </div>
            <DeadCenter >
                <Button variant="outline-success" size="lg" style={{
                    padding: '6px 3em',
                    margin: '0 20px',
                    marginBottom: '20px',
                    flex: 1,
                    whiteSpace: 'nowrap',
                }} >{constants.START}</Button>
            </DeadCenter>
        </MessageDialog>
    );
}
