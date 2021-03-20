import React from 'react';
import { Alert, Button, Modal, ProgressBar } from 'react-bootstrap';
import { UPLOAD_STAGES } from 'services/uploadService';
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
    let fileProgressStatuses = [];
    if (props.fileProgress) {
        for (let [fileName, progress] of props.fileProgress) {
            if (progress === 100) {
                continue;
            }
            fileProgressStatuses.push({ fileName, progress });
        }
        fileProgressStatuses.sort((a, b) => {
            if (b.progress !== -1 && a.progress === -1) return 1;
        });
    }
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
                <div style={{ textAlign: 'center' }}>
                    <h4>
                        {props.uploadStage == UPLOAD_STAGES.UPLOADING
                            ? constants.UPLOAD[props.uploadStage](
                                  props.fileCounter
                              )
                            : constants.UPLOAD[props.uploadStage]}
                    </h4>
                </div>
                {props.now === 100 ? (
                    fileProgressStatuses.length !== 0 && (
                        <Alert variant="warning">
                            {constants.FAILED_UPLOAD_FILE_LIST}
                        </Alert>
                    )
                ) : (
                    <ProgressBar now={props.now} />
                )}
                {fileProgressStatuses && (
                    <div
                        style={{
                            marginTop: '10px',
                            overflow: 'auto',
                            maxHeight: '200px',
                        }}
                    >
                        {fileProgressStatuses.map(({ fileName, progress }) =>
                            constants.FILE_UPLOAD_PROGRESS(fileName, progress)
                        )}
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
