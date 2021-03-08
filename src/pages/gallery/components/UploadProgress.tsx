import React from 'react';
import { Alert, Button, Modal, ProgressBar } from 'react-bootstrap';
import constants from 'utils/strings/constants';

export default function UploadProgress({
    fileCounter,
    uploadStage,
    now,
    uploadErrors,
    closeModal,
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
                {uploadErrors && uploadErrors.length > 0 && (
                    <>
                        <Alert variant="danger">
                            <div
                                style={{
                                    overflow: 'auto',
                                    height: '100px',
                                }}
                            >
                                {uploadErrors.map((error, index) => (
                                    <li key={index}>{error.message}</li>
                                ))}
                            </div>
                        </Alert>
                    </>
                )}
                {now === 100 && (
                    <Modal.Footer>
                        <Button
                            variant="dark"
                            style={{ width: '100%' }}
                            onClick={closeModal}
                        >
                            {constants.CLOSE}
                        </Button>
                    </Modal.Footer>
                )}
            </Modal.Body>
        </Modal>
    );
}
