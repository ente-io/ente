import { Modal, Button, Container, Row } from 'react-bootstrap';
import React from 'react';
import ImportService from 'services/importService';
import constants from 'utils/strings/constants';
import { IoIosArrowForward, IoMdClose } from 'react-icons/io';
import FileUploadIcon from 'components/icons/FileUploadIcon';
import FolderUploadIcon from 'components/icons/FolderUploadIcon';
import { BsGoogle } from 'react-icons/bs';

function UploadTypeRow({ uploadFunc, Icon, uploadName }) {
    return (
        <Row className="justify-content-md-center py-2">
            <Button
                variant="light"
                onClick={uploadFunc}
                style={{ width: '90%', height: '6vh' }}>
                <Container>
                    <Row>
                        <div>
                            <Icon />
                            <b className="ml-2">{uploadName}</b>
                        </div>
                        <div className="ml-auto d-flex align-items-center">
                            <IoIosArrowForward />
                        </div>
                    </Row>
                </Container>
            </Button>
        </Row>
    );
}

function GoogleIcon() {
    return (
        <BsGoogle
            size={25}
            style={{
                marginRight: '0.2em',
                marginLeft: '0.2em',
            }}
        />
    );
}

export default function UploadTypeChoiceModal({
    setElectronFiles,
    showUploadTypeChoiceModal,
    setShowUploadTypeChoiceModal,
    setIsUploadDirs,
}) {
    const hideFiletypeDialog = () => {
        setShowUploadTypeChoiceModal(false);
    };

    const uploadFiles = async () => {
        const files = await ImportService.showUploadFilesDialog();
        hideFiletypeDialog();
        ImportService.setSkipUpdatePendingUploads(false);
        setIsUploadDirs(false);
        setElectronFiles(files);
    };

    const uploadDirs = async () => {
        const files = await ImportService.showUploadDirsDialog();
        hideFiletypeDialog();
        ImportService.setSkipUpdatePendingUploads(false);
        setIsUploadDirs(true);
        setElectronFiles(files);
    };

    const uploadGoogleTakeout = async () => {
        const files = await ImportService.showUploadZipDialog();
        hideFiletypeDialog();
        ImportService.setSkipUpdatePendingUploads(true);
        setIsUploadDirs(true);
        setElectronFiles(files);
    };

    return (
        <Modal
            show={showUploadTypeChoiceModal}
            aria-labelledby="contained-modal-title-vcenter"
            centered
            dialogClassName="file-type-choice-modal">
            <Modal.Header
                onHide={hideFiletypeDialog}
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
                    onClick={hideFiletypeDialog}
                    style={{ cursor: 'pointer' }}
                />
            </Modal.Header>
            <Modal.Body
                style={{
                    height: '10em',
                }}>
                <Container>
                    <UploadTypeRow
                        uploadFunc={uploadFiles}
                        Icon={FileUploadIcon}
                        uploadName={constants.UPLOAD_FILES}
                    />
                    <UploadTypeRow
                        uploadFunc={uploadDirs}
                        Icon={FolderUploadIcon}
                        uploadName={constants.UPLOAD_DIRS}
                    />
                    <UploadTypeRow
                        uploadFunc={uploadGoogleTakeout}
                        Icon={GoogleIcon}
                        uploadName={constants.UPLOAD_GOOGLE_TAKEOUT}
                    />
                </Container>
            </Modal.Body>
        </Modal>
    );
}
