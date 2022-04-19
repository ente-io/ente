import { Modal, Button, Container, Row } from 'react-bootstrap';
import React from 'react';
import constants from 'utils/strings/constants';
import { IoIosArrowForward, IoMdClose } from 'react-icons/io';
import FileUploadIcon from 'components/icons/FileUploadIcon';
import FolderUploadIcon from 'components/icons/FolderUploadIcon';

export default function UploadTypeChoiceModal({
    onHide,
    show,
    uploadFiles,
    uploadFolders,
}) {
    return (
        <Modal
            show={show}
            aria-labelledby="contained-modal-title-vcenter"
            centered
            dialogClassName="file-type-choice-modal">
            <Modal.Header
                onHide={onHide}
                style={{
                    borderBottom: 'none',
                    height: '4em',
                }}>
                <Modal.Title
                    id="contained-modal-title-vcenter"
                    style={{
                        fontSize: '1.8em',
                        marginLeft: '5%',
                        color: 'white',
                    }}>
                    <b>{constants.CHOOSE_UPLOAD_TYPE}</b>
                </Modal.Title>
                <IoMdClose
                    size={30}
                    onClick={onHide}
                    style={{ cursor: 'pointer' }}
                />
            </Modal.Header>
            <Modal.Body
                style={{
                    height: '10em',
                }}>
                <Container>
                    <Row className="justify-content-center py-2">
                        <Button
                            variant="light"
                            onClick={uploadFiles}
                            style={{ width: '90%', height: '3em' }}>
                            <Container>
                                <Row>
                                    <div>
                                        <FileUploadIcon />
                                        <b className="ml-2">
                                            {constants.UPLOAD_FILES}
                                        </b>
                                    </div>
                                    <div className="ml-auto d-flex align-items-center">
                                        <IoIosArrowForward />
                                    </div>
                                </Row>
                            </Container>
                        </Button>
                    </Row>
                    <Row className="justify-content-center py-2">
                        <Button
                            variant="light"
                            onClick={uploadFolders}
                            style={{ width: '90%', height: '3em' }}>
                            <Container>
                                <Row>
                                    <div>
                                        <FolderUploadIcon />
                                        <b className="ml-2">
                                            {constants.UPLOAD_DIRS}
                                        </b>
                                    </div>
                                    <div className="ml-auto d-flex align-items-center">
                                        <IoIosArrowForward />
                                    </div>
                                </Row>
                            </Container>
                        </Button>
                    </Row>
                </Container>
            </Modal.Body>
        </Modal>
    );
}
