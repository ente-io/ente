import Container from 'components/Container';
import React from 'react';
import { Alert, Button, Modal, ProgressBar } from 'react-bootstrap';

export default function UploadProgress(props) {
    return (
        <Modal
            {...props}
            size='lg'
            aria-labelledby='contained-modal-title-vcenter'
            centered
        >
            <Modal.Header closeButton>
                <Modal.Title id='contained-modal-title-vcenter'>
                    Uploading Files
        </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                {props.now == 100 ? (
                    <Alert variant='success'>Upload Completed</Alert>
                ) : (
                        <>
                            <Alert variant='info'>{props.uploadStage} {props.fileCounter.current} of {props.fileCounter.total}</Alert>
                            <ProgressBar animated now={props.now} />
                        </>
                    )}
            </Modal.Body>
        </Modal>
    );
}
