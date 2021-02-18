import React from 'react';
import { Alert, Modal, ProgressBar } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export default function UploadProgress({
    fileCounter,
    uploadStage,
    now,
    uploadErrors,
    ...props
}) {
    return (
        <Modal
            {...props}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop="static"
        >
            <Modal.Header>
                <Modal.Title id="contained-modal-title-vcenter">
                    Uploading Files
                </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                {now === 100 ? (
                    <Alert variant="success">{constants.UPLOAD[3]}</Alert>
                ) : (
                    <>
                        <Alert variant="info">
                            {constants.UPLOAD[uploadStage]}{' '}
                            {fileCounter?.total != 0
                                ? `${fileCounter?.current} ${constants.OF} ${fileCounter?.total}`
                                : ''}
                        </Alert>
                        <ProgressBar animated now={now} />
                    </>
                )}
                {uploadErrors.length && (
                    <Alert variant="danger">
                        <div
                            style={{
                                overflow: 'auto',
                                height: '100px',
                            }}
                        >
                            {uploadErrors.map((error) => (
                                <li>{error.message}</li>
                            ))}
                        </div>
                    </Alert>
                )}
            </Modal.Body>
        </Modal>
    );
}
