import React from 'react';
import {
    Alert, Button, Modal, ProgressBar,
} from 'react-bootstrap';
import { FileRejection } from 'react-dropzone';
import { UPLOAD_STAGES, FileUploadErrorCode } from 'services/uploadService';
import constants from 'utils/strings/constants';

interface Props {
    fileCounter;
    uploadStage;
    now;
    closeModal;
    retryFailed;
    fileProgress: Map<string, number>;
    show;
    fileRejections:FileRejection[]
}
interface FileProgressStatuses{
    fileName:string;
    progress:number;
}
export default function UploadProgress(props: Props) {
    const fileProgressStatuses = [] as FileProgressStatuses[];
    if (props.fileProgress) {
        for (const [fileName, progress] of props.fileProgress) {
            fileProgressStatuses.push({ fileName, progress });
        }
        for (const { file } of props.fileRejections) {
            fileProgressStatuses.push({ fileName: file.name, progress: FileUploadErrorCode.UNSUPPORTED });
        }
        fileProgressStatuses.sort((a, b) => {
            if (b.progress !== -1 && a.progress === -1) return 1;
        });
    }
    return (
        <Modal
            show={props.show}
            onHide={
                props.uploadStage !== UPLOAD_STAGES.FINISH ?
                    () => null :
                    props.closeModal
            }
            aria-labelledby="contained-modal-title-vcenter"
            centered
            backdrop={
                fileProgressStatuses?.length !== 0 ? 'static' : 'true'
            }
        >
            <Modal.Header
                style={{ display: 'flex', justifyContent: 'center', textAlign: 'center', borderBottom: 'none', paddingTop: '30px', paddingBottom: '0px' }}
                closeButton={props.uploadStage === UPLOAD_STAGES.FINISH}
            >

                <h4 style={{ width: '100%' }}>
                    {props.uploadStage === UPLOAD_STAGES.UPLOADING ?
                        constants.UPLOAD[props.uploadStage](
                            props.fileCounter,
                        ) :
                        constants.UPLOAD[props.uploadStage]}
                </h4>
            </Modal.Header>
            <Modal.Body>
                {props.uploadStage===UPLOAD_STAGES.FINISH ? (
                    fileProgressStatuses.length !== 0 && (
                        <Alert variant="warning">
                            {constants.FAILED_UPLOAD_FILE_LIST}
                        </Alert>
                    )
                ) :
                    (props.uploadStage === UPLOAD_STAGES.READING_GOOGLE_METADATA_FILES ||
                        props.uploadStage === UPLOAD_STAGES.UPLOADING) &&
                    (
                        < ProgressBar
                            now={props.now}
                            animated
                            variant="upload-progress-bar"
                        />
                    )}
                {fileProgressStatuses?.length > 0 && (
                    <ul
                        style={{
                            marginTop: '10px',
                            overflow: 'auto',
                            maxHeight: '250px',
                        }}
                    >
                        {fileProgressStatuses.map(({ fileName, progress }) => (
                            <li key={fileName} style={{ marginTop: '12px' }}>
                                {props.uploadStage===UPLOAD_STAGES.FINISH ?
                                    fileName :
                                    constants.FILE_UPLOAD_PROGRESS(
                                        fileName,
                                        progress,
                                    )}
                            </li>
                        ))}
                    </ul>
                )}
                {props.uploadStage === UPLOAD_STAGES.FINISH && (
                    <Modal.Footer style={{ border: 'none' }}>
                        {props.uploadStage===UPLOAD_STAGES.FINISH && (fileProgressStatuses?.length === 0 ? (
                            <Button
                                variant="outline-secondary"
                                style={{ width: '100%' }}
                                onClick={props.closeModal}
                            >
                                {constants.CLOSE}
                            </Button>) : (
                            <Button
                                variant="outline-success"
                                style={{ width: '100%' }}
                                onClick={props.retryFailed}
                            >
                                {constants.RETRY}
                            </Button>))}
                    </Modal.Footer>
                )}
            </Modal.Body>
        </Modal>
    );
}
