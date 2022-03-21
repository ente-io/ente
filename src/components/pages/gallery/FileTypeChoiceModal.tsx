import { Modal, Button, Container, Row } from 'react-bootstrap';
import React from 'react';
import ImportService from 'services/importService';
import { getElectronFiles } from 'utils/upload';
import constants from 'utils/strings/constants';
import { IoIosArrowForward, IoMdClose } from 'react-icons/io';

export default function FileTypeChoiceModal({
    setElectronFiles,
    showFiletypeModal,
    setShowFiletypeModal,
}) {
    const hideFiletypeDialog = () => {
        setShowFiletypeModal(false);
    };

    const uploadFiles = async () => {
        const filePaths = await ImportService.showUploadFilesDialog();
        hideFiletypeDialog();
        const files = await getElectronFiles(filePaths);
        setElectronFiles(files);
    };

    const uploadDirs = async () => {
        const filePaths = await ImportService.showUploadDirsDialog();
        hideFiletypeDialog();
        const files = await getElectronFiles(filePaths);
        setElectronFiles(files);
    };

    return (
        <Modal
            show={showFiletypeModal}
            aria-labelledby="contained-modal-title-vcenter"
            centered
            dialogClassName="file-type-choice-modal">
            <Modal.Header
                onHide={hideFiletypeDialog}
                style={{
                    borderBottom: 'none',
                    height: '8vh',
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
                    onClick={hideFiletypeDialog}
                    style={{ cursor: 'pointer' }}
                />
            </Modal.Header>
            <Modal.Body
                style={{
                    height: '20vh',
                }}>
                <Container>
                    <Row className="justify-content-md-center py-2">
                        <Button
                            variant="light"
                            onClick={uploadFiles}
                            style={{ width: '90%', height: '6vh' }}>
                            <Container>
                                <Row>
                                    <div>
                                        <img
                                            src="/images/file-upload.svg"
                                            className="mr-2"></img>
                                        <b>{constants.UPLOAD_FILES}</b>
                                    </div>
                                    <div className="ml-auto d-flex align-items-center">
                                        <IoIosArrowForward />
                                    </div>
                                </Row>
                            </Container>
                        </Button>
                    </Row>
                    <Row className="justify-content-md-center py-2">
                        <Button
                            variant="light"
                            onClick={uploadDirs}
                            style={{ width: '90%', height: '6vh' }}>
                            <Container>
                                <Row>
                                    <div>
                                        <img
                                            src="/images/folder-upload.svg"
                                            className="mr-2"></img>
                                        <b>{constants.UPLOAD_DIRS}</b>
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
