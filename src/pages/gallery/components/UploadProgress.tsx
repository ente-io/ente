import React from 'react';
import { Alert, Modal, ProgressBar } from 'react-bootstrap';

export default function UploadProgress({ fileCounter, uploadStage, now, ...props }) {
    return (
        <Modal
            {...props}
            size='lg'
            aria-labelledby='contained-modal-title-vcenter'
            centered
            backdrop="static"
        >
            <Modal.Header>
                <Modal.Title id='contained-modal-title-vcenter'>
                    Uploading Files
        </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                {now === 100 ? (
                    <Alert variant='success'>Upload Completed</Alert>
                ) : (
                        <>
                            <Alert variant='info'>{uploadStage} {fileCounter?.current} of {fileCounter?.total}</Alert>
                            <ProgressBar animated now={now} />
                        </>
                    )}
            </Modal.Body>
        </Modal>
    );
}
