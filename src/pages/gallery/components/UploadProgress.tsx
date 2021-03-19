import React from 'react';
import { Alert, Button, Modal, ProgressBar } from 'react-bootstrap';
import constants from 'utils/strings/constants';

interface Props {
    fileCounter;
    uploadStage;
    now;
    uploadErrors;
    closeModal;
    fileProgress: Map<string, number>;
    show;
    onHide;
}
export default function UploadProgress(props: Props) {
    return (
        <Modal
            show={props.show}
            size="lg"
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop="static"
            dialogClassName="ente-modal"
        >
            <Modal.Header>
                <Modal.Title id="contained-modal-title-vcenter">
                    {constants.UPLOADING_FILES}
                </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                {props.now === 100 ? (
                    <Alert variant="success">{constants.UPLOAD[3]}</Alert>
                ) : (
                    <>
                        <Alert variant="info">
                            {constants.UPLOAD[props.uploadStage]}{' '}
                            {props.fileCounter?.total != 0
                                ? `${props.fileCounter?.current} ${constants.OF} ${props.fileCounter?.total}`
                                : ''}
                        </Alert>
                        <ProgressBar animated now={props.now} />
                    </>
                )}
                {props.fileProgress && (
                    <div
                        style={{
                            overflow: 'auto',
                            height: '100px',
                        }}
                    >
                        {(() => {
                            let items = [];
                            for (let [
                                fileName,
                                progress,
                            ] of props.fileProgress) {
                                items.push(
                                    <li key={fileName}>
                                        ({progress} {fileName})
                                    </li>
                                );
                            }
                            return items;
                        })()}
                    </div>
                )}
                {props.now === 100 && (
                    <Modal.Footer>
                        <Button
                            variant="dark"
                            style={{ width: '100%' }}
                            onClick={props.closeModal}
                        >
                            {constants.CLOSE}
                        </Button>
                    </Modal.Footer>
                )}
            </Modal.Body>
        </Modal>
    );
}
